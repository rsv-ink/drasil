# frozen_string_literal: true

class BaseSpecParser < Drasil::Parser
  def parse
    [@response, {}]
  end
end

class BaseSpecUser < Drasil::Base
  uri 'users/(:id)'
  attributes :id, :name
end

RSpec.describe Drasil::Base do
  describe '.page' do
    it 'uses :page when there is no client and no global config' do
      expect(BaseSpecUser.page(2).params).to eq(page: 2)
    end

    it 'uses the global config when set' do
      Drasil::Config.page_query_name = :pagina

      expect(BaseSpecUser.page(2).params).to eq(pagina: 2)
    end

    it 'uses the client config when the resource is bound to a client' do
      client = Drasil::Client.new(base_url: 'https://api.example.com', page_query_name: :pg)
      scoped = client.register_resource(:users, BaseSpecUser)

      expect(scoped.page(2).params).to eq(pg: 2)
    end
  end

  describe '.per_page' do
    it 'uses :per_page when there is no client and no global config' do
      expect(BaseSpecUser.per_page(5).params).to eq(per_page: 5)
    end

    it 'uses the client config when the resource is bound to a client' do
      client = Drasil::Client.new(base_url: 'https://api.example.com', per_page_query_name: :limit)
      scoped = client.register_resource(:users, BaseSpecUser)

      expect(scoped.per_page(5).params).to eq(limit: 5)
    end

    it 'combines with page' do
      client = Drasil::Client.new(
        base_url: 'https://api.example.com',
        page_query_name: :pg,
        per_page_query_name: :limit
      )
      scoped = client.register_resource(:users, BaseSpecUser)

      expect(scoped.page(2).per_page(5).params).to eq(pg: 2, limit: 5)
    end
  end

  describe '.include_root_in_json' do
    it 'keeps request bodies flat by default (v1.x behaviour)' do
      expect(BaseSpecUser.new(name: 'a').to_params).to eq('name' => 'a')
    end

    it 'supports the Spyke DSL in a subclass' do
      klass = Class.new(BaseSpecUser) do
        def self.name = 'DslUser'
        def self.model_name = ActiveModel::Name.new(self, nil, 'DslUser')
      end

      expect { klass.include_root_in_json true }.not_to raise_error
      expect(klass.new(name: 'a').to_params).to eq('dsl_user' => { 'name' => 'a' })
    end
  end

  describe '.connection' do
    it 'uses the client connection when bound to a client' do
      client = Drasil::Client.new(base_url: 'https://api.example.com')
      scoped = client.register_resource(:users, BaseSpecUser)

      expect(scoped.connection).to be(client.connection)
    end

    it 'does not leak the client connection to the unbound class' do
      client = Drasil::Client.new(base_url: 'https://api.example.com')
      client.register_resource(:users, BaseSpecUser)

      expect(BaseSpecUser.drasil_client).to be_nil
    end
  end
end
