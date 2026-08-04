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

    # Request bodies are sent unwrapped by default, matching Drasil v1.x.
    #
    # Spyke defaults `include_root` to true; Drasil has always overridden it to
    # keep payloads flat. Opt into root wrapping per class with the Spyke DSL
    # (`include_root_in_json true`) or per client with
    # `Drasil::Client.new(include_root_in_json: true)`.
    include_root_in_json false

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
