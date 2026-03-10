# frozen_string_literal: true

module ClientHelper
  # Cria um client básico para testes
  def build_test_client(base_url: "https://api.example.com", **options)
    Drasil::Client.new(
      base_url: base_url,
      **options
    )
  end

  # Cria um client com headers de autenticação
  def build_authenticated_client(token: "test-token", **options)
    build_test_client(
      headers: { "Authorization" => "Bearer #{token}" },
      **options
    )
  end

  # Cria múltiplos clients para testes de isolamento
  def build_multiple_clients(count: 2)
    Array.new(count) do |i|
      build_test_client(
        base_url: "https://api#{i + 1}.example.com",
        headers: { "X-Client-ID" => (i + 1).to_s }
      )
    end
  end
end
