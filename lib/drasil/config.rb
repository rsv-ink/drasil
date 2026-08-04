module Drasil
  # Global configuration (DEPRECATED - use Drasil::Client instead)
  #
  # Kept working for v1.x compatibility. New code should build isolated clients
  # with {Drasil::Client.new}.
  class Config
    CONFIG_KEYS = %i[
      base_url
      headers
      include_root_in_json
      page_query_name
      per_page_query_name
      ssl_options
      proxy_options
    ].freeze

    class << self
      attr_accessor(*CONFIG_KEYS)

      def parsers
        @parsers ||= {}
      end

      def add_parser(path, parser)
        raise ArgumentError.new("Parser cannot be nil") if parser.blank?
        raise ArgumentError.new("Parser is not a parser") unless parser.is_a?(Class) && parser < Parser

        UrlPattern.new(path)

        parsers[path] = parser

        true
      end

      def add_middleware(middleware)
        middlewares << middleware
      end

      def middlewares
        @middlewares ||= []
      end

      # Clears every global setting
      #
      # Mostly useful in test suites, so one example does not leak configuration
      # into the next.
      #
      # @return [void]
      def reset!
        CONFIG_KEYS.each { |key| public_send("#{key}=", nil) }

        @parsers = {}
        @middlewares = []
      end

      def parse(url, response)
        parsers.each do |url_pattern, parser_class|
          url_matcher = UrlMatcher.new(url, url_pattern)

          return parser_class.new(response).parse if url_matcher.match?
        end

        raise ParserNotFoundError.new("No parser found for URL: #{url}")
      end
    end
  end
end
