# frozen_string_literal: true

require_relative "payments_api_client/version"

require "drasil"

require "payments_api_client/parsers/default_parser"
require "payments_api_client/resources/seller"

module PaymentsApiClient
  BASE_URL = "your_base_url_here"

  class << self
    # The API client for this gem
    #
    # Each Drasil::Client.new call builds an isolated client, so an application
    # can hold several of them at once (different APIs, versions or tenants).
    #
    # @return [Drasil::Client]
    def client
      @client ||= build_client
    end

    # Rebuilds the client, e.g. with credentials loaded at runtime
    #
    # @return [Drasil::Client]
    def configure(base_url: BASE_URL, token: "your_secret_key_here")
      @client = build_client(base_url: base_url, token: token)
    end

    private

    def build_client(base_url: BASE_URL, token: "your_secret_key_here")
      client = Drasil::Client.new(
        base_url: base_url,
        headers: { "Authorization" => token },
        page_query_name: :page,
        per_page_query_name: :limit

        # SSL config (optional)
        # ssl_options: {
        #   verify: true,
        #   ca_file: "/path/to/ca-bundle.crt",
        #   client_cert: "/path/to/client.crt",
        #   client_key: "/path/to/client.key",
        #   version: :TLSv1_2
        # },

        # Proxy config (optional)
        # proxy_options: {
        #   uri: "http://proxy.example.com:8080",
        #   user: "proxy_username",
        #   password: "proxy_password"
        # }
      )

      client.register_resource(
        :sellers,
        Seller,
        parser: Parsers::DefaultParser,
        parser_path: "/sellers/*"
      )

      client
    end
  end
end
