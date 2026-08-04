# frozen_string_literal: true

module StubHelper
  # Stub de resposta HTTP bem-sucedida
  def stub_successful_response(method:, url:, body: {}, status: 200)
    stub_request(method, url)
      .to_return(
        status: status,
        body: body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub de resposta HTTP com erro
  def stub_error_response(method:, url:, status: 404, body: { error: "Not Found" })
    stub_request(method, url)
      .to_return(
        status: status,
        body: body.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  # Stub de resposta paginada
  def stub_paginated_response(method:, url:, data:, page: 1, total_pages: 1)
    stub_request(method, url)
      .to_return(
        status: 200,
        body: {
          data: data,
          page: page,
          total_pages: total_pages
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
