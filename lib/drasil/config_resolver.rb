# frozen_string_literal: true

module Drasil
  # Resolves configuration values with fallback support
  #
  # This class encapsulates the logic for retrieving configuration values
  # from multiple sources with a defined precedence:
  # 1. Client-specific configuration (highest priority)
  # 2. Global configuration (deprecated, for backward compatibility)
  # 3. Default value (fallback)
  #
  # @example Basic usage
  #   ConfigResolver.resolve(client, :page_query_name, default: :page)
  #   #=> :page (or value from client config)
  #
  # @example With global config fallback
  #   ConfigResolver.resolve(nil, :base_url, default: nil)
  #   #=> Falls back to Drasil::Config.base_url if defined
  class ConfigResolver
    class << self
      # Resolves a configuration value with fallback chain
      #
      # @param client [Drasil::Client, nil] The client instance (or nil for global)
      # @param config_key [Symbol] The configuration key to retrieve
      # @param default [Object] The default value if no config is found
      # @return [Object] The resolved configuration value
      #
      # @example With client
      #   client = Drasil::Client.new(page_query_name: :pg)
      #   ConfigResolver.resolve(client, :page_query_name, default: :page)
      #   #=> :pg
      #
      # @example Without client (global fallback)
      #   ConfigResolver.resolve(nil, :page_query_name, default: :page)
      #   #=> :page (from Drasil::Config when set, otherwise the default)
      def resolve(client, config_key, default:)
        # Priority 1: Client-specific configuration
        if client
          value = client.config.public_send(config_key)
          return value unless value.nil?
        end

        # Priority 2: Global configuration (deprecated)
        if Config.respond_to?(config_key)
          value = Config.public_send(config_key)
          return value unless value.nil?
        end

        # Priority 3: Default value
        default
      end
    end
  end
end
