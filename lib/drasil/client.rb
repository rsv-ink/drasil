# frozen_string_literal: true

module Drasil
  # Main client class for creating isolated API client instances
  #
  # The Client class provides a client-based architecture that allows
  # multiple independent API clients to coexist with isolated configurations,
  # connections, and resource registries.
  #
  # @example Basic usage
  #   client = Drasil::Client.new(
  #     base_url: "https://api.example.com",
  #     headers: { "Authorization" => "Bearer token" }
  #   )
  #
  # @example Registering resources
  #   client.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
  #   client.register_resource(:buyers, Buyer, parser: BuyerParser, parser_path: "/buyers/*")
  #
  # @example Accessing resources
  #   seller = client.sellers.find("123")
  #   buyers = client.buyers.where(status: "active")
  #
  # @example Multiple clients
  #  client_v1 = Drasil::Client.new(base_url: "https://api.example.com/v1")
  #  client_v2 = Drasil::Client.new(base_url: "https://api.example.com/v2")
  class Client
    attr_reader :config, :connection, :resource_registry

    # Creates a new Drasil client instance
    #
    # @param base_url [String] The base URL for the API
    # @param headers [Hash] Default headers to send with requests
    # @param ssl_options [Hash] SSL configuration options
    # @param proxy_options [Hash] Proxy configuration options
    # @param options [Hash] Additional configuration options (passed to Configuration)
    # @yield [config] Optional block to configure the client before building connection
    # @yieldparam config [Configuration] The configuration object
    #
    # @example Basic usage
    #   client = Drasil::Client.new(base_url: "https://api.example.com")
    #
    # @example With block configuration
    #   client = Drasil::Client.new(base_url: "https://api.example.com") do |config|
    #     config.add_middleware(CustomMiddleware)
    #     config.add_parser("/sellers/*", SellerParser)
    #   end
    #
    # @example With SSL
    #   client = Drasil::Client.new(
    #     base_url: "https://api.example.com",
    #     ssl_options: {
    #       verify: true,
    #       client_cert: OpenSSL::X509::Certificate.new(cert_pem),
    #       client_key: OpenSSL::PKey::RSA.new(key_pem)
    #     }
    #   )
    #
    # @example With proxy
    #   client = Drasil::Client.new(
    #     base_url: "https://api.example.com",
    #     proxy_options: { uri: "http://proxy.com:8080" }
    #   )
    def initialize(
      base_url:,
      headers: {},
      ssl_options: nil,
      proxy_options: nil,
      **options,
      &block
    )
      # Create instance configuration
      @config = Client::Configuration.new(
        base_url: base_url,
        headers: headers,
        ssl_options: ssl_options,
        proxy_options: proxy_options,
        **options
      )

      # Yield configuration for customization before building connection
      yield(@config) if block_given?

      # Build Faraday connection (after configuration is complete)
      @connection = build_connection

      # Create resource registry
      @resource_registry = ResourceRegistry.new(self)
    end

    # Registers a resource with this client
    #
    # @param name [Symbol] The name to register the resource under
    # @param resource_class [Class] The resource class (should inherit from Drasil::Base)
    # @param parser [Class, nil] Optional parser class to register
    # @param parser_path [String, nil] Optional URL pattern for the parser
    # @return [Class] The scoped resource class
    #
    # @example
    #   client.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
    def register_resource(name, resource_class, parser: nil, parser_path: nil)
      @resource_registry.register(name, resource_class, parser: parser, parser_path: parser_path)
    end

    # Provides dynamic access to registered resources
    #
    # @example
    #   client.sellers.find("123")
    #   client.buyers.where(status: "active")
    def method_missing(method_name, *args, &block)
      if @resource_registry.registered?(method_name)
        @resource_registry.get(method_name)
      else
        super
      end
    end

    # Checks if the client responds to a method
    #
    # @param method_name [Symbol] The method name to check
    # @param include_private [Boolean] Whether to include private methods
    # @return [Boolean]
    def respond_to_missing?(method_name, include_private = false)
      @resource_registry.registered?(method_name) || super
    end

    private

    # Builds the Faraday connection for this client
    #
    # @return [Faraday::Connection]
    def build_connection
      connection_options = {
        url: @config.base_url
      }
      connection_options[:ssl] = @config.ssl_options if @config.ssl_options
      connection_options[:proxy] = @config.proxy_options if @config.proxy_options

      Faraday.new(connection_options) do |conn|
        conn.headers = @config.headers

        conn.request :multipart
        conn.request :json

        conn.adapter Faraday.default_adapter

        # Use client-aware JSON parser
        conn.use JSONParser, client: self
        conn.use Drasil::Response::RaiseError

        # Add custom middlewares
        @config.middlewares.each do |middleware|
          if middleware.is_a?(Array)
            conn.use(*middleware)
          else
            conn.use middleware
          end
        end
      end
    end
  end
end
