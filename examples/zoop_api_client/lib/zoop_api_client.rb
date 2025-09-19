# frozen_string_literal: true

require_relative "zoop_api_client/version"

require "drasil"

require "zoop_api_client/parsers/default_parser"
require "zoop_api_client/resources/seller"

Drasil.configure do |config|
  config.base_url             = "your_base_url_here"
  config.include_root_in_json = false

  config.page_query_name      = :page
  config.per_page_query_name  = :limit

  config.headers = {
    "Authorization": "your_secret_key_here"
  }

  # SSL config (optional)
  # config.ssl_options = {
  #   verify: true,
  #   ca_file: "/path/to/ca-bundle.crt",
  #   client_cert: "/path/to/client.crt",
  #   client_key: "/path/to/client.key",
  #   version: :TLSv1_2
  # }

  # Proxy config (optional)
  # config.proxy_options = {
  #   uri: "http://proxy.example.com:8080",
  #   user: "proxy_username",
  #   password: "proxy_password"
  # }

  config.add_parser "/sellers/:id", ZoopApiClient::Parsers::DefaultParser
end
