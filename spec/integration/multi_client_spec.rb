# frozen_string_literal: true

RSpec.describe 'Multiple Clients Integration', type: :integration do
  # Simulate Payment API V1 structure
  module PaymentV1
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

    class Account < Drasil::Base
      uri 'accounts/(:id)'
      attributes :id, :name, :email
    end
  end

  # Simulate Payment API V2 structure (different response format)
  module PaymentV2
    class Parser < Drasil::Parser
      def parse
        # V2 wraps data in an 'account' key
        data = @response[:account] || @response
        metadata = {
          page: @response[:pagination]&.dig(:page) || 1,
          total_pages: @response[:pagination]&.dig(:total_pages) || 1
        }
        [data, metadata]
      end
    end

    class Account < Drasil::Base
      uri 'accounts/(:id)'
      attributes :id, :name, :email, :verified
    end
  end

  # Simulate E-commerce API
  module Ecommerce
    class Parser < Drasil::Parser
      def parse
        data = @response[:user] || @response
        metadata = {}
        [data, metadata]
      end
    end

    class User < Drasil::Base
      uri 'users/(:id)'
      attributes :id, :first_name, :last_name, :email
    end
  end

  describe 'Multiple API clients simultaneously' do
    it 'maintains separate configurations for each client' do
      payment_v1_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1',
        headers: { 'Authorization' => 'Bearer payment-v1-token' }
      )

      payment_v2_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2',
        headers: { 'Authorization' => 'Bearer payment-v2-token' }
      )

      ecommerce_client = Drasil::Client.new(
        base_url: 'https://api.store-platform.com/v1',
        headers: { 'X-API-Key' => 'ecommerce-token' }
      )

      expect(payment_v1_client.config.base_url).to eq('https://api.payment-provider.com/v1')
      expect(payment_v2_client.config.base_url).to eq('https://api.payment-provider.com/v2')
      expect(ecommerce_client.config.base_url).to eq('https://api.store-platform.com/v1')
    end

    it 'maintains separate connections for each client' do
      payment_v1_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1',
        headers: { 'Authorization' => 'Bearer payment-v1-token' }
      )

      payment_v2_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2',
        headers: { 'Authorization' => 'Bearer payment-v2-token' }
      )

      ecommerce_client = Drasil::Client.new(
        base_url: 'https://api.store-platform.com/v1',
        headers: { 'X-API-Key' => 'ecommerce-token' }
      )

      expect(payment_v1_client.connection).not_to eq(payment_v2_client.connection)
      expect(payment_v1_client.connection).not_to eq(ecommerce_client.connection)
      expect(payment_v2_client.connection).not_to eq(ecommerce_client.connection)
    end

    it 'maintains separate parsers for each client' do
      payment_v1_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1',
        headers: { 'Authorization' => 'Bearer payment-v1-token' }
      )
      payment_v1_client.register_resource(
        :accounts,
        PaymentV1::Account,
        parser: PaymentV1::Parser,
        parser_path: '/accounts/*'
      )

      payment_v2_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2',
        headers: { 'Authorization' => 'Bearer payment-v2-token' }
      )
      payment_v2_client.register_resource(
        :accounts,
        PaymentV2::Account,
        parser: PaymentV2::Parser,
        parser_path: '/accounts/*'
      )

      v1_parser = payment_v1_client.config.find_parser('/accounts/123')
      v2_parser = payment_v2_client.config.find_parser('/accounts/123')

      expect(v1_parser).to eq(PaymentV1::Parser)
      expect(v2_parser).to eq(PaymentV2::Parser)
    end

    it 'allows accessing resources from different clients' do
      payment_v1_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1',
        headers: { 'Authorization' => 'Bearer payment-v1-token' }
      )
      payment_v1_client.register_resource(
        :accounts,
        PaymentV1::Account,
        parser: PaymentV1::Parser,
        parser_path: '/accounts/*'
      )

      payment_v2_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2',
        headers: { 'Authorization' => 'Bearer payment-v2-token' }
      )
      payment_v2_client.register_resource(
        :accounts,
        PaymentV2::Account,
        parser: PaymentV2::Parser,
        parser_path: '/accounts/*'
      )

      ecommerce_client = Drasil::Client.new(
        base_url: 'https://api.store-platform.com/v1',
        headers: { 'X-API-Key' => 'ecommerce-token' }
      )
      ecommerce_client.register_resource(
        :users,
        Ecommerce::User,
        parser: Ecommerce::Parser,
        parser_path: '/users/*'
      )

      expect(payment_v1_client.accounts).to be < PaymentV1::Account
      expect(payment_v2_client.accounts).to be < PaymentV2::Account
      expect(ecommerce_client.users).to be < Ecommerce::User
    end

    it 'resources use their respective client connections' do
      payment_v1_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1',
        headers: { 'Authorization' => 'Bearer payment-v1-token' }
      )
      payment_v1_client.register_resource(
        :accounts,
        PaymentV1::Account,
        parser: PaymentV1::Parser,
        parser_path: '/accounts/*'
      )

      payment_v2_client = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2',
        headers: { 'Authorization' => 'Bearer payment-v2-token' }
      )
      payment_v2_client.register_resource(
        :accounts,
        PaymentV2::Account,
        parser: PaymentV2::Parser,
        parser_path: '/accounts/*'
      )

      ecommerce_client = Drasil::Client.new(
        base_url: 'https://api.store-platform.com/v1',
        headers: { 'X-API-Key' => 'ecommerce-token' }
      )
      ecommerce_client.register_resource(
        :users,
        Ecommerce::User,
        parser: Ecommerce::Parser,
        parser_path: '/users/*'
      )

      expect(payment_v1_client.accounts.connection).to eq(payment_v1_client.connection)
      expect(payment_v2_client.accounts.connection).to eq(payment_v2_client.connection)
      expect(ecommerce_client.users.connection).to eq(ecommerce_client.connection)
    end

    context 'with stubbed HTTP requests' do
      it 'fetches data from different APIs using different parsers' do
        payment_v1_client = Drasil::Client.new(
          base_url: 'https://api.payment-provider.com/v1',
          headers: { 'Authorization' => 'Bearer payment-v1-token' }
        )
        payment_v1_client.register_resource(
          :accounts,
          PaymentV1::Account,
          parser: PaymentV1::Parser,
          parser_path: '/accounts/*'
        )

        payment_v2_client = Drasil::Client.new(
          base_url: 'https://api.payment-provider.com/v2',
          headers: { 'Authorization' => 'Bearer payment-v2-token' }
        )
        payment_v2_client.register_resource(
          :accounts,
          PaymentV2::Account,
          parser: PaymentV2::Parser,
          parser_path: '/accounts/*'
        )

        ecommerce_client = Drasil::Client.new(
          base_url: 'https://api.store-platform.com/v1',
          headers: { 'X-API-Key' => 'ecommerce-token' }
        )
        ecommerce_client.register_resource(
          :users,
          Ecommerce::User,
          parser: Ecommerce::Parser,
          parser_path: '/users/*'
        )

        # Stub Payment API V1 response
        stub_request(:get, 'https://api.payment-provider.com/v1/accounts/abc')
          .to_return(
            status: 200,
            body: {
              id: 'abc',
              name: 'Account V1',
              email: 'v1@example.com'
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        # Stub Payment API V2 response (different structure)
        stub_request(:get, 'https://api.payment-provider.com/v2/accounts/abc')
          .to_return(
            status: 200,
            body: {
              account: {
                id: 'abc',
                name: 'Account V2',
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

        # Stub E-commerce API response
        stub_request(:get, 'https://api.store-platform.com/v1/users/xyz')
          .to_return(
            status: 200,
            body: {
              user: {
                id: 'xyz',
                first_name: 'John',
                last_name: 'Doe',
                email: 'john@example.com'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        account_v1 = payment_v1_client.accounts.find('abc')
        account_v2 = payment_v2_client.accounts.find('abc')
        user = ecommerce_client.users.find('xyz')

        expect(account_v1.name).to eq('Account V1')
        expect(account_v2.name).to eq('Account V2')
        expect(user.first_name).to eq('John')
      end
    end
  end

  describe 'Same API with multiple versions' do
    it 'allows using v1 and v2 simultaneously' do
      payment_v1 = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1'
      )
      payment_v1.register_resource(
        :accounts,
        PaymentV1::Account,
        parser: PaymentV1::Parser,
        parser_path: '/accounts/*'
      )

      payment_v2 = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2'
      )
      payment_v2.register_resource(
        :accounts,
        PaymentV2::Account,
        parser: PaymentV2::Parser,
        parser_path: '/accounts/*'
      )

      expect(payment_v1.accounts).to be < PaymentV1::Account
      expect(payment_v2.accounts).to be < PaymentV2::Account
      expect(payment_v1.accounts).not_to eq(payment_v2.accounts)
    end

    it 'maintains separate parser registries' do
      payment_v1 = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v1'
      )
      payment_v1.register_resource(
        :accounts,
        PaymentV1::Account,
        parser: PaymentV1::Parser,
        parser_path: '/accounts/*'
      )

      payment_v2 = Drasil::Client.new(
        base_url: 'https://api.payment-provider.com/v2'
      )
      payment_v2.register_resource(
        :accounts,
        PaymentV2::Account,
        parser: PaymentV2::Parser,
        parser_path: '/accounts/*'
      )

      v1_parser = payment_v1.config.find_parser('/accounts/123')
      v2_parser = payment_v2.config.find_parser('/accounts/123')

      expect(v1_parser).to eq(PaymentV1::Parser)
      expect(v2_parser).to eq(PaymentV2::Parser)
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
