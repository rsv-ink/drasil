# frozen_string_literal: true

module Drasil
  # Faraday middleware for parsing JSON responses using registered parsers
  #
  # This middleware is client-aware, meaning it uses the parser registry
  # from the specific client instance it's associated with, rather than
  # a global configuration.
  #
  # @example
  #   # This is typically used internally by Drasil::Client
  #   conn.use JSONParser, client: client_instance
  class JSONParser < Faraday::Middleware
    # Creates a new JSONParser middleware instance
    #
    # @param app [Faraday::Middleware] The next middleware in the stack
    # @param options [Hash] Options hash (Faraday passes middleware args as Hash)
    # @option options [Drasil::Client, nil] :client The client instance (optional for backward compatibility)
    def initialize(app, options = {})
      super(app)
      @client = options[:client]
    end

    # Processes the response after request completion
    #
    # @param env [Faraday::Env] The Faraday environment
    def on_complete(env)
      data, metadata = parse_response(env.url.to_s, load_json(env.body))

      env.body = {
        data: data,
        metadata: metadata,
        errors: []
      }
    end

    private

    # Loads the response body as JSON
    #
    # Empty bodies (204 No Content and friends) are not an error - they simply
    # carry no payload.
    #
    # @param body [String, nil] The raw response body
    # @return [Hash, nil] The parsed JSON, or nil when the body is empty
    # @raise [Drasil::ParsingError] when the body is not valid JSON
    def load_json(body)
      return nil if body.nil? || body.strip.empty?

      MultiJson.load(body, symbolize_keys: true)
    rescue MultiJson::ParseError => e
      raise Drasil::ParsingError, e.message
    end

    # Parses the response using the appropriate parser
    #
    # If a client is available, uses the client's parser registry.
    # Otherwise, falls back to the global Config for backward compatibility.
    #
    # @param url [String] The request URL
    # @param response [Hash, nil] The parsed JSON response
    # @return [Array<Object, Hash>] Tuple of [data, metadata]
    # @raise [ParserNotFoundError] when no parser registry is available
    def parse_response(url, response)
      return [nil, {}] if response.nil?

      if @client
        @client.config.parse(url, response)
      elsif Config.parsers.present?
        Config.parse(url, response)
      else
        raise ParserNotFoundError, "No parser configuration available for URL: #{url}"
      end
    end
  end
end
