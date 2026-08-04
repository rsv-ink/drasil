# frozen_string_literal: true

class PaginationParser < Drasil::Parser
  def parse
    [
      @response[:data],
      { page: @response[:page], total_pages: @response[:total_pages] }
    ]
  end
end

class PaginatedUser < Drasil::Base
  uri 'paginated_users/(:id)'
  attributes :id, :name
end

RSpec.describe 'Pagination', type: :integration do
  let(:base_url) { 'https://api.example.com' }

  describe 'the parser contract' do
    let(:parser_class) { PaginationParser }
    let(:sample_response) { { data: [{ id: 1 }, { id: 2 }], page: 2, total_pages: 10 } }

    it_behaves_like 'a Drasil parser'
    it_behaves_like 'a parser with pagination'
  end

  it 'exposes pagination metadata from the parser' do
    client = build_test_client(base_url: base_url)
    users = client.register_resource(
      :users, PaginatedUser, parser: PaginationParser, parser_path: '/paginated_users/*'
    )
    stub_paginated_response(
      method: :get,
      url: "#{base_url}/paginated_users?page=2&per_page=20",
      data: [{ id: 1 }],
      page: 2,
      total_pages: 5
    )

    relation = users.all.page(2).per_page(20)

    expect(relation.to_a.size).to eq(1)
    expect(relation.current_page).to eq(2)
    expect(relation.total_pages).to eq(5)
    expect(relation.next_page?).to be true
  end

  it 'reports no next page on the last one' do
    client = build_test_client(base_url: base_url)
    users = client.register_resource(
      :users, PaginatedUser, parser: PaginationParser, parser_path: '/paginated_users/*'
    )
    stub_paginated_response(
      method: :get,
      url: "#{base_url}/paginated_users?page=5&per_page=20",
      data: [{ id: 1 }],
      page: 5,
      total_pages: 5
    )

    expect(users.all.page(5).per_page(20).next_page?).to be false
  end

  it 'uses the query parameter names configured in the client' do
    client = build_test_client(base_url: base_url, page_query_name: :pg, per_page_query_name: :limit)
    users = client.register_resource(
      :users, PaginatedUser, parser: PaginationParser, parser_path: '/paginated_users/*'
    )
    request = stub_paginated_response(
      method: :get,
      url: "#{base_url}/paginated_users?pg=3&limit=10",
      data: [],
      page: 3,
      total_pages: 3
    )

    users.all.page(3).per_page(10).to_a

    expect(request).to have_been_requested
  end
end
