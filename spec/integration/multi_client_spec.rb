# frozen_string_literal: true

RSpec.describe 'Multiple Clients Integration', type: :integration do
  # Simulate Zoop V1 API structure
  module ZoopV1
    class Parser < Drasil::Parser
      def parse
        data = @response
        metadata = {
          page: @response[:page] || 1,
          total_pages: @response[:total_pages] || 1
        }
        [data, metadata]
      end
    end

    class Seller < Drasil::Base
      uri 'sellers/(:id)'
      attributes :id, :name, :email
    end
  end

  # Simulate Zoop V2 API structure (different response format)
  module ZoopV2
    class Parser < Drasil::Parser
      def parse
        # V2 wraps data in a 'seller' key
        data = @response[:seller] || @response
        metadata = {
          page: @response[:pagination]&.dig(:page) || 1,
          total_pages: @response[:pagination]&.dig(:total_pages) || 1
        }
        [data, metadata]
      end
    end

    class Seller < Drasil::Base
      uri 'sellers/(:id)'
      attributes :id, :name, :email, :verified
    end
  end

  # Simulate Shopify API
  module Shopify
    class Parser < Drasil::Parser
      def parse
        data = @response[:customer] || @response
        metadata = {}
        [data, metadata]
      end
    end

    class Customer < Drasil::Base
      uri 'customers/(:id)'
      attributes :id, :first_name, :last_name, :email
    end
  end

  describe 'Multiple API clients simultaneously' do
    it 'maintains separate configurations for each client' do
      zoop_v1_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v1-token' }
      )

      zoop_v2_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v2-token' }
      )

      shopify_client = Drasil::Client.new(
        base_url: 'https://mystore.myshopify.com/admin/api/2024-01',
        headers: { 'X-Shopify-Access-Token' => 'shopify-token' }
      )

      expect(zoop_v1_client.config.base_url).to eq('https://api.zoop.com/v1/marketplaces/123')
      expect(zoop_v2_client.config.base_url).to eq('https://api.zoop.com/v2/marketplaces/123')
      expect(shopify_client.config.base_url).to eq('https://mystore.myshopify.com/admin/api/2024-01')
    end

    it 'maintains separate connections for each client' do
      zoop_v1_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v1-token' }
      )

      zoop_v2_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v2-token' }
      )

      shopify_client = Drasil::Client.new(
        base_url: 'https://mystore.myshopify.com/admin/api/2024-01',
        headers: { 'X-Shopify-Access-Token' => 'shopify-token' }
      )

      expect(zoop_v1_client.connection).not_to eq(zoop_v2_client.connection)
      expect(zoop_v1_client.connection).not_to eq(shopify_client.connection)
      expect(zoop_v2_client.connection).not_to eq(shopify_client.connection)
    end

    it 'maintains separate parsers for each client' do
      zoop_v1_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v1-token' }
      )
      zoop_v1_client.register_resource(
        :sellers,
        ZoopV1::Seller,
        parser: ZoopV1::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v2_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v2-token' }
      )
      zoop_v2_client.register_resource(
        :sellers,
        ZoopV2::Seller,
        parser: ZoopV2::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v1_parser = zoop_v1_client.config.find_parser('/sellers/123')
      zoop_v2_parser = zoop_v2_client.config.find_parser('/sellers/123')

      expect(zoop_v1_parser).to eq(ZoopV1::Parser)
      expect(zoop_v2_parser).to eq(ZoopV2::Parser)
    end

    it 'allows accessing resources from different clients' do
      zoop_v1_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v1-token' }
      )
      zoop_v1_client.register_resource(
        :sellers,
        ZoopV1::Seller,
        parser: ZoopV1::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v2_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v2-token' }
      )
      zoop_v2_client.register_resource(
        :sellers,
        ZoopV2::Seller,
        parser: ZoopV2::Parser,
        parser_path: '/sellers/*'
      )

      shopify_client = Drasil::Client.new(
        base_url: 'https://mystore.myshopify.com/admin/api/2024-01',
        headers: { 'X-Shopify-Access-Token' => 'shopify-token' }
      )
      shopify_client.register_resource(
        :customers,
        Shopify::Customer,
        parser: Shopify::Parser,
        parser_path: '/customers/*'
      )

      expect(zoop_v1_client.sellers).to be < ZoopV1::Seller
      expect(zoop_v2_client.sellers).to be < ZoopV2::Seller
      expect(shopify_client.customers).to be < Shopify::Customer
    end

    it 'resources use their respective client connections' do
      zoop_v1_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v1-token' }
      )
      zoop_v1_client.register_resource(
        :sellers,
        ZoopV1::Seller,
        parser: ZoopV1::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v2_client = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123',
        headers: { 'Authorization' => 'Bearer zoop-v2-token' }
      )
      zoop_v2_client.register_resource(
        :sellers,
        ZoopV2::Seller,
        parser: ZoopV2::Parser,
        parser_path: '/sellers/*'
      )

      shopify_client = Drasil::Client.new(
        base_url: 'https://mystore.myshopify.com/admin/api/2024-01',
        headers: { 'X-Shopify-Access-Token' => 'shopify-token' }
      )
      shopify_client.register_resource(
        :customers,
        Shopify::Customer,
        parser: Shopify::Parser,
        parser_path: '/customers/*'
      )

      expect(zoop_v1_client.sellers.connection).to eq(zoop_v1_client.connection)
      expect(zoop_v2_client.sellers.connection).to eq(zoop_v2_client.connection)
      expect(shopify_client.customers.connection).to eq(shopify_client.connection)
    end

    context 'with stubbed HTTP requests' do
      it 'fetches data from different APIs using different parsers' do
        zoop_v1_client = Drasil::Client.new(
          base_url: 'https://api.zoop.com/v1/marketplaces/123',
          headers: { 'Authorization' => 'Bearer zoop-v1-token' }
        )
        zoop_v1_client.register_resource(
          :sellers,
          ZoopV1::Seller,
          parser: ZoopV1::Parser,
          parser_path: '/sellers/*'
        )

        zoop_v2_client = Drasil::Client.new(
          base_url: 'https://api.zoop.com/v2/marketplaces/123',
          headers: { 'Authorization' => 'Bearer zoop-v2-token' }
        )
        zoop_v2_client.register_resource(
          :sellers,
          ZoopV2::Seller,
          parser: ZoopV2::Parser,
          parser_path: '/sellers/*'
        )

        shopify_client = Drasil::Client.new(
          base_url: 'https://mystore.myshopify.com/admin/api/2024-01',
          headers: { 'X-Shopify-Access-Token' => 'shopify-token' }
        )
        shopify_client.register_resource(
          :customers,
          Shopify::Customer,
          parser: Shopify::Parser,
          parser_path: '/customers/*'
        )

        # Stub Zoop V1 response
        stub_request(:get, 'https://api.zoop.com/v1/marketplaces/123/sellers/abc')
          .to_return(
            status: 200,
            body: {
              id: 'abc',
              name: 'Seller V1',
              email: 'v1@example.com'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Zoop V2 response (different structure)
        stub_request(:get, 'https://api.zoop.com/v2/marketplaces/123/sellers/abc')
          .to_return(
            status: 200,
            body: {
              seller: {
                id: 'abc',
                name: 'Seller V2',
                email: 'v2@example.com',
                verified: true
              },
              pagination: {
                page: 1,
                total_pages: 1
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Shopify response
        stub_request(:get, 'https://mystore.myshopify.com/admin/api/2024-01/customers/xyz')
          .to_return(
            status: 200,
            body: {
              customer: {
                id: 'xyz',
                first_name: 'John',
                last_name: 'Doe',
                email: 'john@example.com'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        seller_v1 = zoop_v1_client.sellers.find('abc')
        seller_v2 = zoop_v2_client.sellers.find('abc')
        customer = shopify_client.customers.find('xyz')

        expect(seller_v1.name).to eq('Seller V1')
        expect(seller_v2.name).to eq('Seller V2')
        expect(customer.first_name).to eq('John')
      end
    end
  end

  describe 'Same API with multiple versions' do
    it 'allows using v1 and v2 simultaneously' do
      zoop_v1 = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123'
      )
      zoop_v1.register_resource(
        :sellers,
        ZoopV1::Seller,
        parser: ZoopV1::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v2 = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123'
      )
      zoop_v2.register_resource(
        :sellers,
        ZoopV2::Seller,
        parser: ZoopV2::Parser,
        parser_path: '/sellers/*'
      )

      expect(zoop_v1.sellers).to be < ZoopV1::Seller
      expect(zoop_v2.sellers).to be < ZoopV2::Seller
      expect(zoop_v1.sellers).not_to eq(zoop_v2.sellers)
    end

    it 'maintains separate parser registries' do
      zoop_v1 = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v1/marketplaces/123'
      )
      zoop_v1.register_resource(
        :sellers,
        ZoopV1::Seller,
        parser: ZoopV1::Parser,
        parser_path: '/sellers/*'
      )

      zoop_v2 = Drasil::Client.new(
        base_url: 'https://api.zoop.com/v2/marketplaces/123'
      )
      zoop_v2.register_resource(
        :sellers,
        ZoopV2::Seller,
        parser: ZoopV2::Parser,
        parser_path: '/sellers/*'
      )

      v1_parser = zoop_v1.config.find_parser('/sellers/123')
      v2_parser = zoop_v2.config.find_parser('/sellers/123')

      expect(v1_parser).to eq(ZoopV1::Parser)
      expect(v2_parser).to eq(ZoopV2::Parser)
    end
  end

  describe 'Thread safety' do
    it 'allows concurrent requests from multiple clients' do
      client1 = Drasil::Client.new(base_url: 'https://api1.example.com')
      client2 = Drasil::Client.new(base_url: 'https://api2.example.com')

      threads = []

      threads << Thread.new do
        client1.config.base_url
      end

      threads << Thread.new do
        client2.config.base_url
      end

      results = threads.map(&:value)

      expect(results).to contain_exactly(
        'https://api1.example.com',
        'https://api2.example.com'
      )
    end
  end
end
