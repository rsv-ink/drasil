# frozen_string_literal: true

require_relative 'drasil/version'

require 'spyke'
require 'multi_json'

# Core errors
require 'drasil/error'
require 'drasil/errors/parser_not_found_error'
require 'drasil/errors/resource_not_found_error'

# Configuration and parsing
require 'drasil/config'
require 'drasil/parser'
require 'drasil/url_matcher'
require 'drasil/url_pattern'

# Middleware
require 'drasil/response/raise_error'
require 'drasil/json_parser'

# Client-based architecture
require 'drasil/client/configuration'
require 'drasil/resource_registry'
require 'drasil/client'

# Rails integration
require 'drasil/railtie' if defined?(Rails)

module Drasil
  class Error < StandardError; end

  class << self
    # Global configuration (DEPRECATED - use Drasil::Client.new instead)
    #
    # This method is maintained for backward compatibility but will be
    # removed in version 3.0.0. Please migrate to the client-based approach.
    #
    # @deprecated Use {Drasil::Client.new} instead
    #
    # @example Old way (deprecated)
    #   Drasil.configure do |config|
    #     config.base_url = "https://api.example.com"
    #   end
    #
    # @example New way (recommended)
    #   client = Drasil::Client.new(
    #     base_url: "https://api.example.com",
    #     headers: { "Authorization" => "Bearer token" }
    #   )
    #   client.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
    #
    # @yieldparam config [Drasil::Config] The global configuration object
    def configure
      warn_deprecation

      yield(Config)

      raise Error.new('No parsers have been registered.') if Config.parsers.blank?

      connection_options = {
        url: Config.base_url
      }
      connection_options[:ssl] = Config.ssl_options if Config.ssl_options
      connection_options[:proxy] = Config.proxy_options if Config.proxy_options

      Spyke::Base.connection = Faraday.new(connection_options) do |conn|
        conn.headers = Config.headers

        conn.request   :multipart
        conn.request   :json

        conn.adapter   Faraday.default_adapter

        conn.use JSONParser
        conn.use Drasil::Response::RaiseError

        Config.middlewares.each do |middleware|
          conn.use middleware
        end
      end
    end

    private

    def warn_deprecation
      @deprecation_warned ||= false
      return if @deprecation_warned

      warn <<~WARNING

        [DEPRECATION] Drasil.configure is deprecated and will be removed in version 3.0.0.

        Please migrate to the client-based approach:

          # Before (deprecated):
          Drasil.configure do |config|
            config.base_url = "https://api.example.com"
            config.headers = { "Authorization" => "Bearer token" }
          end

          # After (recommended):
          client = Drasil::Client.new(
            base_url: "https://api.example.com",
            headers: { "Authorization" => "Bearer token" }
          )
          client.register_resource(:sellers, Seller, parser: SellerParser, parser_path: "/sellers/*")
          client.sellers.find("123")

        See migration guide: https://github.com/rsv-ink/drasil/README.md#guia-de-migração

      WARNING

      @deprecation_warned = true
    end
  end
end

require 'drasil/base'
