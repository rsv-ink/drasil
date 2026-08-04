# frozen_string_literal: true

# Regression coverage for write operations through a registered resource.
#
# Scoped resource classes are anonymous, and ActiveModel raises
# "Class name cannot be blank" on any operation that needs #model_name -
# create, save, update and to_params. Reads never touch it, which is why the
# original suite (GET-only stubs) reported green while every write was broken.
class WriteOpsParser < Drasil::Parser
  def parse
    [@response[:data] || @response, {}]
  end
end

class WriteOpsUser < Drasil::Base
  uri 'users/(:id)'
  attributes :id, :name, :email
end

RSpec.describe 'Write operations through a registered resource', type: :integration do
  let(:base_url) { 'https://api.example.com' }
  let(:client) { build_test_client(base_url: base_url) }
  let!(:users) do
    client.register_resource(:users, WriteOpsUser, parser: WriteOpsParser, parser_path: '/users/*')
  end

  # Captures the request body sent to WebMock
  def capture(method, url, response: { data: { id: 1, name: 'saved' } })
    captured = {}
    stub_request(method, url)
      .with { |req| captured[:body] = req.body; true }
      .to_return(status: 200, body: response.to_json, headers: { 'Content-Type' => 'application/json' })
    captured
  end

  describe 'create' do
    it 'posts the attributes and returns the persisted record' do
      captured = capture(:post, "#{base_url}/users")

      user = users.create(name: 'João', email: 'joao@example.com')

      expect(user.id).to eq(1)
      expect(captured[:body]).to eq({ name: 'João', email: 'joao@example.com' }.to_json)
    end
  end

  describe 'save' do
    it 'puts the attributes for a persisted record' do
      captured = capture(:put, "#{base_url}/users/5", response: { data: { id: 5, name: 'q' } })

      record = users.new(id: 5, name: 'q')

      expect(record.save).to be_truthy
      # :id is embedded in the URL, so Spyke leaves it out of the body
      expect(captured[:body]).to eq({ name: 'q' }.to_json)
    end
  end

  describe 'update' do
    it 'puts the changed attributes' do
      stub_request(:get, "#{base_url}/users/7")
        .to_return(status: 200, body: { data: { id: 7, name: 'old' } }.to_json)
      captured = capture(:put, "#{base_url}/users/7", response: { data: { id: 7, name: 'new' } })

      user = users.find(7)
      user.update(name: 'new')

      expect(captured[:body]).to include('new')
    end
  end

  describe 'destroy' do
    it 'deletes the record' do
      stub_request(:get, "#{base_url}/users/9")
        .to_return(status: 200, body: { data: { id: 9 } }.to_json)
      request = stub_request(:delete, "#{base_url}/users/9")
        .to_return(status: 200, body: { data: {} }.to_json)

      users.find(9).destroy

      expect(request).to have_been_requested
    end
  end

  describe 'model_name' do
    it 'is delegated to the parent resource class' do
      expect(users.model_name.to_s).to eq('WriteOpsUser')
      expect(users.new(name: 'a').to_params).to eq('name' => 'a')
    end
  end

  describe 'root wrapping' do
    it 'wraps the body when the client opts in' do
      wrapping_client = build_test_client(base_url: base_url, include_root_in_json: true)
      scoped = wrapping_client.register_resource(
        :users, WriteOpsUser, parser: WriteOpsParser, parser_path: '/users/*'
      )
      captured = capture(:post, "#{base_url}/users")

      scoped.create(name: 'João')

      expect(captured[:body]).to eq({ write_ops_user: { name: 'João' } }.to_json)
    end

    it 'keeps the body flat when the client opts out explicitly' do
      flat_client = build_test_client(base_url: base_url, include_root_in_json: false)
      scoped = flat_client.register_resource(
        :users, WriteOpsUser, parser: WriteOpsParser, parser_path: '/users/*'
      )
      captured = capture(:post, "#{base_url}/users")

      scoped.create(name: 'João')

      expect(captured[:body]).to eq({ name: 'João' }.to_json)
    end
  end

  describe 'reads still work' do
    it 'finds a record' do
      stub_successful_response(
        method: :get, url: "#{base_url}/users/1", body: { data: { id: 1, name: 'lido' } }
      )

      expect(users.find(1).name).to eq('lido')
    end

    it 'lists a collection through the same parser pattern' do
      stub_successful_response(
        method: :get, url: "#{base_url}/users", body: { data: [{ id: 1 }, { id: 2 }] }
      )

      expect(users.all.to_a.size).to eq(2)
    end

    it 'raises on an error response' do
      stub_error_response(method: :get, url: "#{base_url}/users/404", status: 404)

      expect { users.find(404) }.to raise_error(Drasil::ResourceNotFound)
    end
  end

  describe 'the scoped class itself' do
    let(:resource_class) { users }

    it_behaves_like 'a Drasil resource'
    it_behaves_like 'a resource with CRUD operations'
    it_behaves_like 'a scoped resource'
  end
end
