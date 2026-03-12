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
      # @param include_root_in_json [Boolean] Whether to include root in JSON (default: false)
      # @param page_query_name [Symbol] Query parameter name for pagination page (default: :page)
      # @param per_page_query_name [Symbol] Query parameter name for pagination limit (default: :per_page)
      # @param ssl_options [Hash] SSL configuration options for Faraday
      # @param proxy_options [Hash] Proxy configuration options for Faraday
      def initialize(
        client:,
        base_url: nil,
        headers: {},
        include_root_in_json: false,
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
        raise ArgumentError, "Parser cannot be nil" if parser_class.nil?
        raise ArgumentError, "Parser is not a parser" unless parser_class < Parser

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
        @parsers.each do |url_pattern, parser_class|
          url_matcher = UrlMatcher.new(url, url_pattern)

          if url_matcher.match?
            parser = parser_class.new(response)
            return parser.parse
          end
        end

        raise ParserNotFoundError, "No parser found for URL: #{url}"
      end

      # Finds a parser class for the given URL
      #
      # @param url [String] The URL to find a parser for
      # @return [Class] The parser class
      # @raise [ParserNotFoundError] if no matching parser is found
      #
      # @example
      #   parser_class = config.find_parser("/sellers/123")
      def find_parser(url)
        @parsers.each do |url_pattern, parser_class|
          url_matcher = UrlMatcher.new(url, url_pattern)
          return parser_class if url_matcher.match?
        end

        raise ParserNotFoundError, "No parser found for URL: #{url}"
      end

      # Registers a resource with this configuration
      #
      # Creates a scoped version of the resource class that is bound to
      # this configuration's client. If a parser is provided, it will be
      # registered with this configuration.
      #
      # @param name [Symbol] The name to register the resource under
      # @param resource_class [Class] The resource class (should inherit from Drasil::Base)
      # @param parser [Class, nil] Optional parser class to register for this resource
      # @param parser_path [String, nil] Optional URL pattern for the parser
      # @return [Class] The scoped resource class
      #
      # @example Without parser
      #   config.register_resource(:sellers, Seller)
      #
      # @example With parser
      #   config.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
      def register_resource(name, resource_class, parser: nil, parser_path: nil)
        # Register parser if provided
        add_parser(parser_path, parser) if parser && parser_path

        # Create a new class that inherits from the resource class
        # and is bound to this client
        scoped_class = create_scoped_class(resource_class)

        # Store the scoped class in the registry
        @resources[name] = scoped_class

        scoped_class
      end

      # Retrieves a registered resource
      #
      # @param name [Symbol] The name of the resource to retrieve
      # @return [Class] The scoped resource class
      # @raise [ResourceNotFoundError] if the resource is not registered
      #
      # @example
      #   sellers_class = config.get_resource(:sellers)
      #   seller = sellers_class.find("123")
      def get_resource(name)
        @resources[name] || raise(
          ResourceNotFoundError,
          "Resource '#{name}' not found in registry. " \
          "Available resources: #{@resources.keys.join(', ')}"
        )
      end

      # Checks if a resource is registered
      #
      # @param name [Symbol] The name of the resource to check
      # @return [Boolean] true if registered, false otherwise
      #
      # @example
      #   config.resource_registered?(:sellers) #=> true
      #   config.resource_registered?(:unknown) #=> false
      def resource_registered?(name)
        @resources.key?(name)
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

      # Creates a scoped class that inherits from the resource class
      # and overrides connection and configuration to use this client
      #
      # @param resource_class [Class] The base resource class
      # @return [Class] A new class bound to this client
      def create_scoped_class(resource_class)
        client = @client

        scoped_class = Class.new(resource_class) do
          # Store reference to client
          @_drasil_client = client

          # Override class methods to use this client
          class << self
            attr_accessor :_drasil_client

            def drasil_client
              @_drasil_client
            end

            def drasil_client=(value)
              @_drasil_client = value
            end

            def connection
              @_drasil_client ? @_drasil_client.connection : super
            end
          end

          # Set the client
          self._drasil_client = client
        end

        # Copy the URI from the parent class if it's explicitly set
        # This prevents Spyke from inferring the URI from the scoped class name
        scoped_class.uri(resource_class.uri) if resource_class.respond_to?(:uri) && resource_class.uri

        scoped_class
      end
    end
  end
end
