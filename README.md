# Drasil

**Drasil** é uma gem Ruby que fornece uma base para construir clientes de API com uma interface limpa e similar ao ActiveRecord. Construído sobre [Spyke](https://github.com/balvig/spyke) e [Faraday](https://github.com/lostisland/faraday), oferece uma arquitetura flexível baseada em clientes que suporta múltiplas conexões de API, versões e configurações simultaneamente.

## ✨ Funcionalidades

- 🎯 **Arquitetura Baseada em Clientes** - Crie múltiplos clientes de API isolados
- 🔄 **Suporte Multi-Versão** - Use diferentes versões de API simultaneamente
- 🔌 **Pronto para Multi-Tenancy** - Credenciais diferentes por tenant
- 🧵 **Thread-Safe** - Instâncias de cliente isoladas
- 📦 **Interface Similar ao ActiveRecord** - Operações CRUD familiares
- 🔍 **Parsers Customizados** - Parsing de resposta flexível
- 🚀 **Suporte a Paginação** - Helpers de paginação integrados
- 🔐 **Suporte SSL/TLS** - Suporte completo a SSL e mTLS
- 🌐 **Suporte a Proxy** - Configuração de proxy HTTP

## 📋 Sumário

- [Instalação](#instalação)
- [Início Rápido](#início-rápido)
- [Uso Baseado em Cliente (v2.0+)](#uso-baseado-em-cliente-v20)
  - [Criando Clientes](#criando-clientes)
  - [Múltiplos Clientes](#múltiplos-clientes)
  - [Múltiplas Versões de API](#múltiplas-versões-de-api)
- [Uso Legado (v1.x - Descontinuado)](#uso-legado-v1x---descontinuado)
- [Tópicos Avançados](#tópicos-avançados)
  - [Paginação](#paginação)
  - [Tratamento de Erros](#tratamento-de-erros)
  - [Criação de Parsers](#criação-de-parsers)
  - [Criação de Resources](#criação-de-resources)
  - [Configuração SSL/mTLS](#configuração-sslmtls)
  - [Configuração de Proxy](#configuração-de-proxy)
- [Testes](#testes)
- [Guia de Migração](#guia-de-migração)
- [Referências](#referências)

## Instalação

Adicione Drasil ao seu Gemfile:

```ruby
gem 'drasil', '~> 2.0'
```

Ou instale diretamente:

```bash
gem install drasil
```

## Início Rápido

```ruby
require 'drasil'

# Criar um cliente
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  headers: { "Authorization" => "Bearer SEU_TOKEN" }
)

# Definir um resource
class User < Drasil::Base
  attributes :id, :name, :email
end

# Registrar o resource
client.register_resource(:users, User, parser: SeuParser, parser_path: "/users/*")

# Usar!
user = client.users.find(123)
users = client.users.all
new_user = client.users.create(name: "João", email: "joao@example.com")
```

## Uso Baseado em Cliente (v2.0+)

### Criando Clientes

A forma moderna de usar o Drasil é através de instâncias de cliente:

```ruby
# Cliente básico
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  headers: {
    "Authorization" => "Bearer SEU_TOKEN",
    "Content-Type" => "application/json"
  }
)

# Cliente com SSL
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  ssl_options: {
    verify: true,
    ca_file: "/caminho/para/ca-bundle.crt",
    client_cert: OpenSSL::X509::Certificate.new(cert_pem),
    client_key: OpenSSL::PKey::RSA.new(key_pem)
  }
)

# Cliente com proxy
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  proxy_options: {
    uri: "http://proxy.example.com:8080",
    user: "usuario_proxy",
    password: "senha_proxy"
  }
)

# Cliente com paginação customizada
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  page_query_name: :pg,        # padrão: :page
  per_page_query_name: :limit  # padrão: :per_page
)
```

#### Formato do corpo das requisições

Por padrão o corpo vai **sem root**, como em toda a linha v1.x:

```ruby
user.to_params  #=> { "name" => "João" }
```

Para APIs que esperam o recurso encapsulado, ative por cliente ou por classe:

```ruby
# por cliente (vale para todos os resources registrados nele)
client = Drasil::Client.new(base_url: "https://api.example.com", include_root_in_json: true)

# por classe (DSL do Spyke)
class User < Drasil::Base
  include_root_in_json true
end

user.to_params  #=> { "user" => { "name" => "João" } }
```

### Múltiplos Clientes

Execute múltiplos clientes de API simultaneamente:

```ruby
# Cliente de Pagamentos
payment_api = Drasil::Client.new(
  base_url: "https://api.payments.example.com/v1",
  headers: { "Authorization" => "Bearer PAYMENT_TOKEN" }
)

# Cliente de E-commerce
ecommerce_api = Drasil::Client.new(
  base_url: "https://api.ecommerce.example.com/v2",
  headers: { "X-API-Key" => "ECOMMERCE_KEY" }
)

# Cliente de CRM
crm_api = Drasil::Client.new(
  base_url: "https://api.crm.example.com/v1",
  headers: { "Authorization" => "Bearer CRM_TOKEN" }
)

# Registrar resources para cada cliente
payment_api.register_resource(:transactions, Transaction, parser: PaymentParser, parser_path: "/transactions/*")
ecommerce_api.register_resource(:products, Product, parser: EcommerceParser, parser_path: "/products/*")
crm_api.register_resource(:customers, Customer, parser: CrmParser, parser_path: "/customers/*")

# Usar independentemente
transaction = payment_api.transactions.find("txn_123")
product = ecommerce_api.products.find("prod_456")
customer = crm_api.customers.find("cust_789")
```

### Múltiplas Versões de API

Use diferentes versões da mesma API:

```ruby
# Cliente API V1
api_v1 = Drasil::Client.new(
  base_url: "https://api.example.com/v1",
  headers: { "Authorization" => "Bearer TOKEN" }
)

# Cliente API V2
api_v2 = Drasil::Client.new(
  base_url: "https://api.example.com/v2",
  headers: { "Authorization" => "Bearer TOKEN" }
)

# Parsers diferentes para versões diferentes
api_v1.register_resource(:users, User, parser: V1Parser, parser_path: "/users/*")
api_v2.register_resource(:users, User, parser: V2Parser, parser_path: "/users/*")

# Usar ambas as versões simultaneamente
user_v1 = api_v1.users.find(123)  # Usa parser V1
user_v2 = api_v2.users.find(123)  # Usa parser V2
```

## Uso Legado (v1.x - Descontinuado)

> ⚠️ **Descontinuado**: Este padrão de uso está descontinuado e será removido na versão 3.0.0. Por favor, migre para a abordagem baseada em cliente.

```ruby
Drasil.configure do |config|
  config.base_url = "https://api.example.com"
  config.headers = { "Authorization" => "Bearer TOKEN" }
  config.add_parser "/users/*", UserParser
end

# Ainda funciona mas mostra avisos de deprecação
user = User.find(123)
```

Veja o [Guia de Migração](#guia-de-migração) para atualizar da v1.x para v2.x.

## Tópicos Avançados

### Paginação

Resources podem ser paginados usando os métodos `page` e `per_page`:

```ruby
# Paginar resultados
users = client.users.all.page(2).per_page(20)

# Metadados de paginação
users.total_pages    # Número total de páginas
users.current_page   # Número da página atual
users.next_page?     # Retorna true se houver mais páginas

# Iterar através das páginas
page = 1
loop do
  users = client.users.all.page(page).per_page(100)
  break unless users.next_page?

  users.each { |user| processar(user) }
  page += 1
end
```

### Tratamento de Erros

Drasil lança exceções específicas para diferentes erros HTTP:

| Classe de Exceção | Status HTTP | Descrição |
|------------------|-------------|-----------|
| `Drasil::BadRequestError` | 400 | Requisição inválida |
| `Drasil::UnauthorizedError` | 401 | Falha na autenticação |
| `Drasil::ForbiddenError` | 403 | Acesso proibido |
| `Drasil::ResourceNotFound` | 404 | Recurso não encontrado |
| `Drasil::ProxyAuthError` | 407 | Falha na autenticação do proxy |
| `Drasil::RequestTimeoutError` | 408 | Timeout da requisição |
| `Drasil::ConflictError` | 409 | Conflito de recurso |
| `Drasil::UnprocessableEntityError` | 422 | Erro de validação |
| `Drasil::ClientError` | 4xx | Erro genérico do cliente |
| `Drasil::ServerError` | 5xx | Erro do servidor |
| `Drasil::TimeoutError` | - | Timeout da requisição |
| `Drasil::ConnectionFailed` | - | Falha na conexão |
| `Drasil::SSLError` | - | Erro SSL/TLS |
| `Drasil::ParsingError` | - | Erro ao processar resposta |

**Uso:**

```ruby
begin
  user = client.users.find(123)
rescue Drasil::ResourceNotFound => e
  puts "Usuário não encontrado"
rescue Drasil::UnauthorizedError => e
  puts "Credenciais inválidas"
rescue Drasil::ServerError => e
  puts "Erro no servidor da API: #{e.message}"
end
```

### Criação de Parsers

Parsers transformam respostas da API no formato esperado pelo Drasil:

```ruby
# Parser para resposta de coleção
class UserCollectionParser < Drasil::Parser
  def parse
    data = @response[:users]
    metadata = {
      total_pages: @response[:pagination][:total_pages],
      page: @response[:pagination][:current_page]
    }

    [data, metadata]
  end
end

# Parser para resposta de recurso único
class UserParser < Drasil::Parser
  def parse
    data = @response[:user]
    metadata = {}

    [data, metadata]
  end
end

# Registrar parser com cliente
client.register_resource(
  :users,
  User,
  parser: UserCollectionParser,
  parser_path: "/users"
)
```

**Regras de Parser:**
- Deve herdar de `Drasil::Parser`
- Deve implementar o método `parse`
- Deve retornar tupla `[data, metadata]`
- Um parser pode ser reutilizado para múltiplas rotas

**Padrões de `parser_path`:**

Os padrões são *globs* de caminho, não expressões regulares. O casamento roda contra o
path da URL (host e query string são ignorados) e é ancorado em fronteira de segmento:

| Padrão | Combina | Não combina |
|---|---|---|
| `/users/:id` | `/users/123`, `/v1/users/123` | `/users`, `/users_archive/1` |
| `/users/*` | `/users`, `/users/123` | `/usersXYZ`, `/admin/users_backup` |
| `/users/**` | `/users/1/posts/2` | `/users` |
| `/users/` | qualquer caminho abaixo de `/users/` | — |

O padrão mais específico ganha, independente da ordem de registro — mais segmentos
primeiro, depois menos curingas. Um `/users/:id` genérico não engole mais um
`/users/1/detail` registrado depois.

### Criação de Resources

Resources representam entidades da API:

```ruby
class User < Drasil::Base
  # Definir atributos
  attributes :id, :name, :email, :created_at, :updated_at

  # Definir associações
  # Sem opções, o Spyke deriva "users/:user_id/profile" e "users/:user_id/posts"
  has_one :profile
  has_many :posts

  # Para rotas fora da convenção, passe a URI como opção (nunca posicional)
  # e use a foreign key do pai como placeholder:
  #   has_many :posts, uri: "posts/for_user/:user_id"

  # Métodos de classe customizados
  def self.find_by_email(email)
    where(email: email).first
  end

  # Métodos de instância customizados
  def full_name
    "#{first_name} #{last_name}"
  end
end

# Uso
client.register_resource(:users, User, parser: UserParser, parser_path: "/users/*")

# Operações CRUD
user = client.users.find(123)
user = client.users.create(name: "João", email: "joao@example.com")
user.update(name: "Maria")
user.destroy

# Consultas
users = client.users.all
users = client.users.where(status: "active")
user = client.users.find_by_email("joao@example.com")

# Associações
profile = user.profile
posts = user.posts
```

### Configuração SSL/mTLS

Suporte completo para SSL e TLS mútuo (mTLS):

```ruby
# SSL básico com verificação
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  ssl_options: {
    verify: true,
    ca_file: "/caminho/para/ca-bundle.crt"
  }
)

# TLS Mútuo (mTLS)
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  ssl_options: {
    verify: true,
    ca_file: "/caminho/para/ca-bundle.crt",
    client_cert: OpenSSL::X509::Certificate.new(File.read("client.crt")),
    client_key: OpenSSL::PKey::RSA.new(File.read("client.key")),
    version: :TLSv1_2
  }
)

# Exemplo com autenticação mútua completa
SECURE_CLIENT = Drasil::Client.new(
  base_url: "https://api.secure-service.example.com/v1",
  headers: {
    "Authorization" => "Basic #{Base64.strict_encode64("#{API_KEY}:#{API_SECRET}")}",
    "x-api-key" => API_KEY
  },
  ssl_options: {
    verify: true,
    client_cert: OpenSSL::X509::Certificate.new(ENV['CLIENT_CERT_PEM']),
    client_key: OpenSSL::PKey.read(ENV['CLIENT_KEY_PEM']),
    ca_file: ENV['CA_BUNDLE_FILE']
  }
)
```

### Configuração de Proxy

Configure proxies HTTP:

```ruby
# Proxy simples
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  proxy_options: {
    uri: "http://proxy.example.com:8080"
  }
)

# Proxy autenticado
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  proxy_options: {
    uri: "http://proxy.example.com:8080",
    user: "usuario_proxy",
    password: "senha_proxy"
  }
)
```

## Testes

Use WebMock para simular requisições HTTP nos testes:

```ruby
require 'webmock/rspec'

RSpec.describe User do
  let(:client) do
    Drasil::Client.new(base_url: "https://api.example.com")
  end

  before do
    client.register_resource(:users, User, parser: UserParser, parser_path: "/users/*")
  end

  describe "#find" do
    context "quando o usuário existe" do
      before do
        stub_request(:get, "https://api.example.com/users/123")
          .to_return(
            status: 200,
            body: { user: { id: 123, name: "João" } }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "retorna o usuário" do
        user = client.users.find(123)
        expect(user.name).to eq("João")
      end
    end

    context "quando o usuário não existe" do
      before do
        stub_request(:get, "https://api.example.com/users/999")
          .to_return(status: 404)
      end

      it "lança ResourceNotFound" do
        expect { client.users.find(999) }.to raise_error(Drasil::ResourceNotFound)
      end
    end
  end
end
```

## Guia de Migração

### Migrando da v1.x para v2.0

**Antes (v1.x - Descontinuado):**

```ruby
# Configuração global
Drasil.configure do |config|
  config.base_url = "https://api.example.com"
  config.headers = { "Authorization" => "Bearer TOKEN" }
  config.add_parser "/users/*", UserParser
end

# Uso direto do resource
user = User.find(123)
```

**Depois (v2.0 - Recomendado):**

```ruby
# Abordagem baseada em cliente
client = Drasil::Client.new(
  base_url: "https://api.example.com",
  headers: { "Authorization" => "Bearer TOKEN" }
)

# Registrar resources
client.register_resource(:users, User, parser: UserParser, parser_path: "/users/*")

# Usar via cliente
user = client.users.find(123)
```

**Benefícios da v2.0:**
- ✅ Múltiplos clientes simultaneamente
- ✅ Diferentes versões de API lado a lado
- ✅ Thread-safe por design
- ✅ Melhor suporte a multi-tenancy
- ✅ Configurações isoladas

## Estrutura de Projeto

Ao criar uma nova gem de cliente de API:

```
seu_api_client/
├── lib/
│   ├── seu_api_client.rb          # Ponto de entrada principal
│   └── seu_api_client/
│       ├── parsers/                # Parsers de resposta
│       │   ├── default_parser.rb
│       │   └── collection_parser.rb
│       └── resources/              # Resources da API
│           ├── user.rb
│           └── product.rb
├── spec/
│   ├── fixtures/                   # Respostas simuladas
│   │   ├── users/
│   │   │   ├── 200.json
│   │   │   └── 404.json
│   │   └── products/
│   ├── resources/                  # Testes de resources
│   │   ├── user_spec.rb
│   │   └── product_spec.rb
│   └── support/
│       └── webmock.rb             # Helpers de teste
└── seu_api_client.gemspec
```

## Referências

- [Data Mapper Pattern - ROM](https://api.rom-rb.org/rom-http/)
- [Shopify API](https://github.com/Shopify/shopify-api-ruby/tree/v13.1.0/lib/shopify_api/rest/resources/2023_07)
- [Swagger Code Generator - OpenApi](https://github.com/OpenAPITools/openapi-generator)
  - [Documentação de Instalação](https://openapi-generator.tech/docs/installation)
- [Octokit (Github client)](https://github.com/octokit/octokit.rb)
- [Dropbox](https://github.com/zendesk/dropbox-api)
- [Google Api Client](https://github.com/googleapis/google-api-ruby-client/tree/main/google-api-client)
- [Spyke](https://github.com/balvig/spyke)
- [Twitter API Client](https://github.com/sferik/twitter) (biblioteca Ruby que fornece uma interface para acessar a API RESTful do Twitter)
- [SoundCloud Ruby API Client](https://github.com/soundcloud/soundcloud-ruby) (biblioteca DEPRECATED Ruby que fornece uma interface para acessar a API RESTful do SoundCloud)
- [JsonApiClient](https://github.com/JsonApiClient/json_api_client)
- [ActiveResource Base (Ruby on Rails)](https://api.rubyonrails.org/v3.2.6/classes/ActiveResource/Base.html)
- [Onde colocar código de chamada de API externa em um projeto Ruby on Rails](https://stackoverflow.com/questions/71030683/where-would-i-put-external-api-call-code-in-my-rails-project) ➝ [Usando Service Objects em Ruby on Rails](https://blog.appsignal.com/2020/06/17/using-service-objects-in-ruby-on-rails.html)
- [RESTful Web Services Cookbook (PDF, ano 2010)](https://github.com/codeteenager/fe-ebook/blob/master/RESTful%20Web%20Services%20Cookbook.pdf)

## Contribuindo

1. Faça um fork do repositório
2. Crie sua branch de feature (`git checkout -b feature/funcionalidade-incrivel`)
3. Commit suas mudanças (`git commit -m 'Adiciona funcionalidade incrível'`)
4. Push para a branch (`git push origin feature/funcionalidade-incrivel`)
5. Abra um Pull Request