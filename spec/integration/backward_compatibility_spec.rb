# frozen_string_literal: true

# Locks the v1.x behaviours that the client-based refactor must preserve.
class CompatParser < Drasil::Parser
  def parse
    [@response[:data] || @response, { page: @response[:page], total_pages: @response[:total_pages] }]
  end
end

class CompatUser < Drasil::Base
  uri 'users/(:id)'
  attributes :id, :name
end

RSpec.describe 'Backward compatibility with v1.x', type: :integration do
  describe 'request body format' do
    it 'sends attributes unwrapped by default, exactly like v1.x' do
      expect(CompatUser.new(name: 'a').to_params).to eq('name' => 'a')
    end

    it 'honours the global include_root_in_json setting' do
      Drasil.configure do |config|
        config.base_url = 'https://legacy.example.com'
        config.include_root_in_json = true
        config.add_parser '/users/*', CompatParser
      end

      expect(CompatUser.new(name: 'a').to_params).to eq('compat_user' => { 'name' => 'a' })
    end
  end

  describe 'Drasil.configure' do
    it 'works end to end without explicit headers' do
      Drasil.configure do |config|
        config.base_url = 'https://legacy.example.com'
        config.add_parser '/users/*', CompatParser
      end

      stub_request(:get, 'https://legacy.example.com/users/1')
        .to_return(status: 200, body: { data: { id: 1, name: 'legado' } }.to_json)

      expect(CompatUser.find(1).name).to eq('legado')
    end

    it 'sends the configured headers' do
      Drasil.configure do |config|
        config.base_url = 'https://legacy.example.com'
        config.headers = { 'X-Legacy' => '1' }
        config.add_parser '/users/*', CompatParser
      end

      stub_request(:get, 'https://legacy.example.com/users/1')
        .with(headers: { 'X-Legacy' => '1' })
        .to_return(status: 200, body: { data: { id: 1, name: 'legado' } }.to_json)

      expect(CompatUser.find(1).name).to eq('legado')
    end

    it 'honours custom pagination query names' do
      Drasil.configure do |config|
        config.base_url = 'https://legacy.example.com'
        config.page_query_name = :pagina
        config.per_page_query_name = :tamanho
        config.add_parser '/users/*', CompatParser
      end

      expect(CompatUser.page(3).per_page(7).params).to eq(pagina: 3, tamanho: 7)
    end

    it 'creates records through the global connection' do
      Drasil.configure do |config|
        config.base_url = 'https://legacy.example.com'
        config.add_parser '/users/*', CompatParser
      end

      stub_request(:post, 'https://legacy.example.com/users')
        .to_return(status: 200, body: { data: { id: 9, name: 'novo' } }.to_json)

      expect(CompatUser.create(name: 'novo').id).to eq(9)
    end

    it 'emits a deprecation warning' do
      Drasil.instance_variable_set(:@deprecation_warned, false)

      expect do
        Drasil.configure do |config|
          config.base_url = 'https://legacy.example.com'
          config.add_parser '/users/*', CompatParser
        end
      end.to output(/\[DEPRECATION\] Drasil\.configure is deprecated/).to_stderr
    end
  end

  describe 'Drasil::Config' do
    it 'accepts middlewares' do
      expect { Drasil::Config.add_middleware(Drasil::Response::RaiseError) }.not_to raise_error
      expect(Drasil::Config.middlewares).to include(Drasil::Response::RaiseError)
    end

    it 'raises ParserNotFoundError when no pattern matches' do
      Drasil::Config.add_parser '/users/*', CompatParser

      expect { Drasil::Config.parse('/unknown/1', {}) }
        .to raise_error(Drasil::ParserNotFoundError)
    end
  end
end
