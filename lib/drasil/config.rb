module Drasil
  class Config
    class << self
      attr_accessor *%i[
        base_url
        headers
        include_root_in_json
        page_query_name
        per_page_query_name
        ssl_options
        proxy_options
      ]
      attr_reader :parsers

      def add_parser(path, parser)
        raise ArgumentError.new("Parser cannot be nil") if parser.blank?
        raise ArgumentError.new("Parser is not a parser") unless parser < Parser

        UrlPattern.new(path)

        @parsers ||= {}
        @parsers[path] = parser

        true
      end

      def add_middleware(middleware)
        @middlewares ||= {}

        @middlewares << middleware
      end

      def middlewares
        @middlewares || []
      end

      def parse(url, response)
        parser_class = @parsers.each do |url_pattern, parser_class|
          url_matcher = UrlMatcher.new(url, url_pattern)

          if url_matcher.match?
            parser = parser_class.new(response)

            return parser.parse
          end
        end

        raise StandardError.new("Parser not found")
      end
    end
  end
end
