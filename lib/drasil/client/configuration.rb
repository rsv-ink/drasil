# frozen_string_literal: true

module Drasil
  class Client
    # Instance-based configuration for Drasil clients.
    #
    # This class manages configuration for individual Drasil::Client instances,
    # allowing multiple clients with different configurations to coexist.
    #
    # @example Creating a configuration
    #   config = Drasil::Client::Configuration.new(
    #     base_url: "https://api.example.com",
    #     headers: { "Authorization" => "Bearer token" },
    #     page_query_name: :page,
    #     per_page_query_name: :limit
    #   )
    #
    # @example Adding parsers
    #   config.add_parser("/sellers/:id", SellerParser)
    #   config.add_parser("/buyers/*", BuyerParser)
    #
    # @example Finding parsers
    #   parser = config.find_parser("/sellers/123")
    class Configuration
      attr_accessor :base_url,
                    :headers,
                    :include_root_in_json,
                    :page_query_name,
                    :per_page_query_name,
                    :ssl_options,
                    :proxy_options

      attr_reader :parsers, :middlewares

      # Creates a new Configuration instance
      #
      # @param base_url [String] The base URL for the API
      # @param headers [Hash] Default headers to send with requests
      # @param include_root_in_json [Boolean] Whether to include root in JSON (default: false)
      # @param page_query_name [Symbol] Query parameter name for pagination page (default: :page)
      # @param per_page_query_name [Symbol] Query parameter name for pagination limit (default: :per_page)
      # @param ssl_options [Hash] SSL configuration options for Faraday
      # @param proxy_options [Hash] Proxy configuration options for Faraday
      def initialize(
        base_url: nil,
        headers: {},
        include_root_in_json: false,
        page_query_name: :page,
        per_page_query_name: :per_page,
        ssl_options: nil,
        proxy_options: nil
      )
        @base_url = base_url
        @headers = headers || {}
        @include_root_in_json = include_root_in_json
        @page_query_name = page_query_name
        @per_page_query_name = per_page_query_name
        @ssl_options = ssl_options
        @proxy_options = proxy_options
        @parsers = {}
        @middlewares = []
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
    end
  end
end
