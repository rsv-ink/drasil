# frozen_string_literal: true

module Drasil
  class Client
    # Client context that manages configuration, parsers, middlewares, and resources.
    #
    # This class serves as a unified registry for all client-specific components,
    # allowing multiple clients with different configurations and resources to coexist.
    #
    # @example Creating a context
    #   context = Drasil::Client::Context.new(
    #     client: client,
    #     base_url: "https://api.example.com",
    #     headers: { "Authorization" => "Bearer token" },
    #     page_query_name: :page,
    #     per_page_query_name: :limit
    #   )
    #
    # @example Adding parsers
    #   context.add_parser("/sellers/:id", SellerParser)
    #   context.add_parser("/buyers/*", BuyerParser)
    #
    # @example Registering resources
    #   context.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
    #
    # @example Finding parsers
    #   parser = context.find_parser("/sellers/123")
    class Context
      attr_accessor :base_url,
                    :headers,
                    :include_root_in_json,
                    :page_query_name,
                    :per_page_query_name,
                    :ssl_options,
                    :proxy_options

      attr_reader :parsers, :middlewares, :resources, :client

      # Creates a new Context instance
      #
      # @param client [Drasil::Client] The client this context belongs to
      # @param base_url [String] The base URL for the API
      # @param headers [Hash] Default headers to send with requests
      # @param include_root_in_json [Boolean, nil] Whether to wrap request bodies in a
      #   root key. Defaults to nil, meaning "not informed" - resources keep whatever
      #   they (or Drasil::Base) already define. Pass true/false to override explicitly.
      # @param page_query_name [Symbol] Query parameter name for pagination page (default: :page)
      # @param per_page_query_name [Symbol] Query parameter name for pagination limit (default: :per_page)
      # @param ssl_options [Hash] SSL configuration options for Faraday
      # @param proxy_options [Hash] Proxy configuration options for Faraday
      def initialize(
        client:,
        base_url: nil,
        headers: {},
        include_root_in_json: nil,
        page_query_name: :page,
        per_page_query_name: :per_page,
        ssl_options: nil,
        proxy_options: nil
      )
        @client = client
        @base_url = base_url
        @headers = headers || {}
        @include_root_in_json = include_root_in_json
        @page_query_name = page_query_name
        @per_page_query_name = per_page_query_name
        @ssl_options = ssl_options
        @proxy_options = proxy_options
        @parsers = {}
        @middlewares = []
        @resources = {}
        @scoped_classes = {}
      end

      # Returns the version of a resource class bound to this client
      #
      # Memoized per resource class, so the same parent always maps to the same
      # scoped class. Used both by {#register_resource} and by associations, which
      # must stay inside the same client instead of falling back to the global
      # connection.
      #
      # @param resource_class [Class] The resource class to scope
      # @return [Class] The scoped class, or the original class when it cannot be bound
      def scoped_class_for(resource_class)
        return resource_class unless resource_class.respond_to?(:drasil_client=)
        return resource_class if resource_class.drasil_client == @client

        @scoped_classes[resource_class] ||= create_scoped_class(resource_class)
      end

      # Adds a parser for a specific URL pattern
      #
      # @param path [String] URL pattern (e.g., "/sellers/:id")
      # @param parser_class [Class] Parser class that inherits from Drasil::Parser
      # @return [Boolean] true if parser was added successfully
      # @raise [ArgumentError] if parser is nil or not a Parser subclass
      #
      # @example
      #   config.add_parser("/sellers/:id", SellerParser)
      def add_parser(path, parser_class)
        raise ArgumentError, 'Parser cannot be nil' if parser_class.nil?
        raise ArgumentError, 'Parser is not a parser' unless parser_class.is_a?(Class) && parser_class < Parser

        # Validate URL pattern
        UrlPattern.new(path)

        @parsers[path] = parser_class

        true
      end

      # Adds a middleware to the connection stack
      #
      # @param middleware [Class, Array] Middleware class or array with middleware and options
      # @return [Array] Updated middlewares array
      #
      # @example
      #   config.add_middleware(CustomMiddleware)
      #   config.add_middleware([LoggingMiddleware, { verbose: true }])
      def add_middleware(middleware)
        @middlewares << middleware
      end

      # Finds and instantiates a parser for the given URL
      #
      # @param url [String] The URL to find a parser for
      # @param response [Hash] The response data to parse
      # @return [Array<Object, Hash>] Tuple of [data, metadata]
      # @raise [ParserNotFoundError] if no matching parser is found
      #
      # @example
      #   data, metadata = config.parse("/sellers/123", response_hash)
      def parse(url, response)
        find_parser(url).new(response).parse
      end

      # Finds a parser class for the given URL
      #
      # Patterns are evaluated from the most specific to the most generic, so
      # registration order does not decide which parser wins.
      #
      # @param url [String] The URL to find a parser for
      # @return [Class] The parser class
      # @raise [ParserNotFoundError] if no matching parser is found
      #
      # @example
      #   parser_class = config.find_parser("/sellers/123")
      def find_parser(url)
        sorted_parsers.each do |url_pattern, parser_class|
          return parser_class if UrlMatcher.new(url, url_pattern).match?
        end

        raise ParserNotFoundError, "No parser found for URL: #{url}"
      end

      # Registers a resource with this configuration
      #
      # Creates a scoped version of the resource class that is bound to
      # this configuration's client. If a parser is provided, it will be
      # registered with this configuration.
      #
      # Registering the same name with the same resource class again is a no-op
      # and returns the scoped class created the first time, so references handed
      # out earlier stay valid.
      #
      # @param name [Symbol, String] The name to register the resource under
      # @param resource_class [Class] The resource class (should inherit from Drasil::Base)
      # @param parser [Class, nil] Optional parser class to register for this resource
      # @param parser_path [String, nil] Optional URL pattern for the parser
      # @return [Class] The scoped resource class
      # @raise [ArgumentError] if parser is provided without parser_path or vice versa
      #
      # @example Without parser
      #   config.register_resource(:sellers, Seller)
      #
      # @example With parser
      #   config.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
      def register_resource(name, resource_class, parser: nil, parser_path: nil)
        # Validate parser arguments - both or neither must be provided
        if parser && !parser_path
          raise ArgumentError, 'parser_path must be provided when parser is specified'
        elsif parser_path && !parser
          raise ArgumentError, 'parser must be provided when parser_path is specified'
        end

        name = normalize_resource_name(name)

        # Register parser if both are provided
        add_parser(parser_path, parser) if parser && parser_path

        # Create (or reuse) a class that inherits from the resource class
        # and is bound to this client
        @resources[name] = scoped_class_for(resource_class)
      end

      # Retrieves a registered resource
      #
      # @param name [Symbol, String] The name of the resource to retrieve
      # @return [Class] The scoped resource class
      # @raise [ResourceNotFoundError] if the resource is not registered
      #
      # @example
      #   sellers_class = config.get_resource(:sellers)
      #   seller = sellers_class.find("123")
      def get_resource(name)
        @resources[normalize_resource_name(name)] || raise(
          ResourceNotFoundError,
          "Resource '#{name}' not found in registry. " \
          "Available resources: #{@resources.keys.join(', ')}"
        )
      end

      # Checks if a resource is registered
      #
      # @param name [Symbol, String] The name of the resource to check
      # @return [Boolean] true if registered, false otherwise
      #
      # @example
      #   config.resource_registered?(:sellers) #=> true
      #   config.resource_registered?(:unknown) #=> false
      def resource_registered?(name)
        @resources.key?(normalize_resource_name(name))
      end

      # Returns all registered resource names
      #
      # @return [Array<Symbol>] List of registered resource names
      #
      # @example
      #   config.resource_names #=> [:sellers, :buyers, :transactions]
      def resource_names
        @resources.keys
      end

      private

      # Normalizes a resource name so strings and symbols are interchangeable
      #
      # @param name [Symbol, String] The resource name
      # @return [Symbol]
      def normalize_resource_name(name)
        name.to_sym
      rescue NoMethodError
        raise ArgumentError, "Resource name must respond to #to_sym, got #{name.class}"
      end

      # Parsers ordered from the most specific pattern to the most generic one
      #
      # More path segments wins first, then fewer wildcards, then the longer pattern.
      #
      # @return [Array<Array(String, Class)>]
      def sorted_parsers
        @parsers.sort_by do |pattern, _parser_class|
          [-pattern.count('/'), pattern.scan(/\*|:[a-zA-Z0-9_-]+/).size, -pattern.length]
        end
      end

      # Creates a scoped class that inherits from the resource class
      # and is bound to this client
      #
      # The scoped class is anonymous, so it delegates `model_name` to its parent.
      # Without that delegation ActiveModel raises "Class name cannot be blank" on
      # every write operation (create/save/update) and on URI inference.
      #
      # Associations are re-bound to this client too: Spyke resolves an association
      # target by constant name, which would otherwise land on an unbound class with
      # no connection.
      #
      # @param resource_class [Class] The base resource class
      # @return [Class] A new class bound to this client
      def create_scoped_class(resource_class)
        context = self

        scoped_class = Class.new(resource_class) do
          class << self
            def model_name
              superclass.model_name
            end
          end

          define_method(:association) do |name|
            association = super(name)
            scoped_target = context.scoped_class_for(association.klass)
            association.instance_variable_set(:@klass, scoped_target)
            association
          end
        end

        scoped_class.drasil_client = @client

        # Copy the URI from the parent class when it resolves to one, so the
        # scoped class never re-infers a different path.
        scoped_class.uri(resource_class.uri) if resource_class.respond_to?(:uri) && resource_class.uri

        # Apply the client-wide root wrapping preference when informed
        scoped_class.include_root_in_json(@include_root_in_json) unless @include_root_in_json.nil?

        scoped_class
      end
    end
  end
end
