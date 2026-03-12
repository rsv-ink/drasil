# frozen_string_literal: true

module Drasil
  # Base class for Drasil resources
  #
  # This class extends Spyke::Base with client-aware functionality,
  # allowing resources to be bound to specific client instances with
  # isolated configurations and connections.
  #
  # @example Basic resource
  #   class Seller < Drasil::Base
  #     attributes :id, :name, :email
  #   end
  #
  # @example With client binding
  #   client = Drasil::Client.new(base_url: "https://api.example.com")
  #   client.register_resource(:sellers, Seller)
  #   seller = client.sellers.find("123")
  class Base < Spyke::Base
    # Client-aware class attribute
    # When set, this resource will use the client's connection and configuration
    class_attribute :drasil_client

    class << self
      # Override connection to use client's connection if available
      #
      # @return [Faraday::Connection] The connection for this resource
      def connection
        if drasil_client
          drasil_client.connection
        else
          super
        end
      end

      # Sets the connection for this resource
      #
      # @param conn [Faraday::Connection] The connection to use
      def connection=(conn)
        super
      end

      # Adds pagination to the query
      #
      # Uses the client's configuration for page query name if available,
      # otherwise falls back to default behavior
      #
      # @param number [Integer] The page number
      # @return [Spyke::Relation]
      #
      # @example
      #   Seller.page(2).per_page(20)
      def page(number)
        page_query_name = ConfigResolver.resolve(
          drasil_client,
          :page_query_name,
          default: :page
        )

        where(Hash[page_query_name, number])
      end

      # Sets the number of records per page
      #
      # Uses the client's configuration for per_page query name if available,
      # otherwise falls back to default behavior
      #
      # @param number [Integer] The number of records per page
      # @return [Spyke::Relation]
      #
      # @example
      #   Seller.per_page(20).page(2)
      def per_page(number)
        per_page_query_name = ConfigResolver.resolve(
          drasil_client,
          :per_page_query_name,
          default: :per_page
        )

        where(Hash[per_page_query_name, number])
      end

      # Gets or sets the include_root_in_json setting with client-aware fallback
      #
      # When called with a value, sets the include_root_in_json setting.
      # When called without a value, returns explicitly set value if available,
      # otherwise falls back to client or global configuration.
      #
      # @param value [Boolean, nil] Optional value to set
      # @return [Boolean] The include_root_in_json setting
      #
      # @example Setting value using DSL (preserves Spyke DSL compatibility)
      #   class User < Drasil::Base
      #     include_root_in_json true
      #   end
      #
      # @example Setting value using assignment
      #   class User < Drasil::Base
      #     self.include_root_in_json = true
      #   end
      #
      # @example Using client config (no explicit value set)
      #   client = Drasil::Client.new(include_root_in_json: true)
      #   client.register_resource(:users, User)
      #   client.users.include_root_in_json #=> true (from client config)
      def include_root_in_json(value = :not_provided)
        # If a value is explicitly provided, set it (DSL-style usage)
        if value != :not_provided
          self.include_root_in_json = value
          return value
        end

        # Check if explicitly set via setter (e.g., self.include_root_in_json = true)
        # The setter is provided by Spyke's class_attribute and sets @include_root_in_json
        if instance_variable_defined?(:@include_root_in_json) && !@include_root_in_json.nil?
          return @include_root_in_json
        end

        # Fall back to client or global config
        ConfigResolver.resolve(drasil_client, :include_root_in_json, default: false)
      end
    end
  end
end

# Extensions to Spyke::Relation for pagination metadata
class Spyke::Relation
  # Returns the total number of pages from metadata
  #
  # @return [Integer, nil]
  def total_pages
    metadata[:total_pages]
  end

  # Checks if there is a next page
  #
  # @return [Boolean]
  def next_page?
    metadata[:page].to_i < metadata[:total_pages]
  end

  # Returns the current page number
  #
  # @return [Integer, nil]
  def current_page
    metadata[:page]
  end
end
