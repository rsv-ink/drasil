# frozen_string_literal: true

# Spyke resolves an association target by constant name, so a resource registered
# in a client would reach an *unbound* class with no connection ("undefined method
# `get' for nil"). Scoped classes re-bind their associations to the same client.
class AssocParser < Drasil::Parser
  def parse
    [@response[:data] || @response, {}]
  end
end

class AssocProfile < Drasil::Base
  attributes :id, :bio
end

class AssocPost < Drasil::Base
  attributes :id, :title
end

class AssocAuthor < Drasil::Base
  uri 'assoc_authors/(:id)'
  attributes :id, :name
  has_one :assoc_profile
  has_many :assoc_posts
end

RSpec.describe 'Associations on a client-scoped resource', type: :integration do
  let(:base_url) { 'https://api.example.com' }
  let(:client) { build_authenticated_client(token: 'assoc-token', base_url: base_url) }
  let!(:authors) do
    client.register_resource(:authors, AssocAuthor, parser: AssocParser, parser_path: '/assoc_**')
  end

  let(:author) do
    stub_request(:get, "#{base_url}/assoc_authors/1")
      .to_return(status: 200, body: { data: { id: 1, name: 'autora' } }.to_json)
    authors.find(1)
  end

  it 'loads a has_one association through the client connection' do
    stub_request(:get, "#{base_url}/assoc_authors/1/assoc_profile")
      .to_return(status: 200, body: { data: { id: 7, bio: 'oi' } }.to_json)

    expect(author.assoc_profile.bio).to eq('oi')
  end

  it 'loads a has_many association through the client connection' do
    stub_request(:get, "#{base_url}/assoc_authors/1/assoc_posts")
      .to_return(status: 200, body: { data: [{ id: 1 }, { id: 2 }] }.to_json)

    expect(author.assoc_posts.to_a.size).to eq(2)
  end

  it 'sends the client headers on association requests' do
    request = stub_request(:get, "#{base_url}/assoc_authors/1/assoc_profile")
      .with(headers: { 'Authorization' => 'Bearer assoc-token' })
      .to_return(status: 200, body: { data: { id: 7 } }.to_json)

    author.assoc_profile.id

    expect(request).to have_been_requested
  end

  it 'keeps the unbound association class free of any client' do
    stub_request(:get, "#{base_url}/assoc_authors/1/assoc_profile")
      .to_return(status: 200, body: { data: { id: 7 } }.to_json)

    author.assoc_profile.id

    expect(AssocProfile.drasil_client).to be_nil
  end

  it 'routes associations of different clients to their own base_url' do
    other = Drasil::Client.new(base_url: 'https://other.example.com')
    other_authors = other.register_resource(
      :authors, AssocAuthor, parser: AssocParser, parser_path: '/assoc_**'
    )
    stub_request(:get, 'https://other.example.com/assoc_authors/1')
      .to_return(status: 200, body: { data: { id: 1 } }.to_json)
    other_request = stub_request(:get, 'https://other.example.com/assoc_authors/1/assoc_profile')
      .to_return(status: 200, body: { data: { id: 9 } }.to_json)

    other_authors.find(1).assoc_profile.id

    expect(other_request).to have_been_requested
  end
end
