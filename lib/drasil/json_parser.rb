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
    # @param client [Drasil::Client, nil] The client instance (optional for backward compatibility)
    def initialize(app, client: nil)
      super(app)
      @client = client
    end

    # Processes the response after request completion
    #
    # @param env [Faraday::Env] The Faraday environment
    def on_complete(env)
      json = MultiJson.load(env.body, symbolize_keys: true)

      data, metadata = parse_response(env.url.to_s, json)

      env.body = {
        data: data,
        metadata: metadata,
        errors: []
      }
    end

    private

    # Parses the response using the appropriate parser
    #
    # If a client is available, uses the client's parser registry.
    # Otherwise, falls back to the global Config for backward compatibility.
    #
    # @param url [String] The request URL
    # @param response [Hash] The parsed JSON response
    # @return [Array<Object, Hash>] Tuple of [data, metadata]
    def parse_response(url, response)
      if @client
        @client.config.parse(url, response)
      elsif defined?(Config)
        Config.parse(url, response)
      else
        raise ParserNotFoundError, "No parser configuration available for URL: #{url}"
      end
    end

    # Checks if the HTTP status indicates an error
    #
    # @param http_status [Integer] The HTTP status code
    # @return [Boolean] true if status is an error (not 2xx)
    def error?(http_status)
      !http_status.to_s.start_with?("2")
    end
  end
end
