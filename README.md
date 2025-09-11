# Drasil

## Sumário

- [Introdução](#introdução)
- [Problemas conhecidos](#problemas-conhecidos)
- [Instalação](#instalação)
- [Estrutura de pastas dos Clients](#estrutura-de-pastas-dos-clients)
- [Usos](#usos)
  - [Paginação](#paginação)
  - [Erros](#erros)
  - [Criação de parsers](#criação-de-parsers)
  - [Criação de resources](#criação-de-resources)
- [Testes](#testes)
- [Referências](#referências)

## Introdução

Este documento serve de referência para a instalação da gem `drasil`. Além disso, ele inclui o passo a passo para a criação, configuração e testes de novos API Client's.

Esta gem foi construída utilizando a biblioteca [Spyke](https://github.com/balvig/spyke) e usa o [Faraday](https://github.com/infobyte/faraday) como cliente HTTP. Ela inclui a base para a criação de novos API Client's. Por utilizar a gem `spyke`, ela fornece uma interface similar ao ActiveRecord.

Exemplos de uso:

```ruby
# Criar um novo seller utilizando o método create
ZoopApiClient::Seller.create(
  first_name: "John"
)

# Criar um novo seller utilizando o método save
seller = ZoopApiClient::Seller.new(
  first_name: "John"
)
seller.save

# Buscar um seller pelo id
seller = ZoopApiClient::Seller.find("123456789")

# Atualizar o atributo `first_name`
seller.update(first_name: "John")

# Deletar o seller
seller.destroy
```

## Problemas conhecidos

### Retornos polimórficos dos métodos de comunicação da Zoop

```ruby
   # app/service_layers/zoop/base_object/seller/api/endpoints.rb:25

  def create_bank_account(bank_account_params, zoop_seller_id)
    @bank_account = Zoop::BaseObject::Seller::Api::Bank::BankAccounts.new(@client)
    token = @bank_account.generate_token(data: bank_account_params)["id"]
    response = @bank_account.associate_to_seller(seller_id: zoop_seller_id, token: token)

    begin
      JSON.parse(response)
    rescue StandardError => e
      puts "error => #{e}"
    end
  end
```

### Falta de padronização nos métodos de criação e atualização de resources

```ruby
# Creates a card token
def create_new_card_token(data:)
  path = "cards/tokens"
  response = @client.post(path: path, data: data)
end

# Creates a buyer
def create_buyer(data:)
  path = "buyers"
  response = @client.post(path: path, data: data)
  JSON.parse(response) if response.present?
end
```

### Falta de padronização na paginação de resources

Não há uma interface bem definida para acessar rotas paginadas:

```ruby
# Page and limit are present in params
Api::Zoop::Client.account_balance.find_historic_account_balance_by_seller(
  seller_id: @zoop_id,
  params: params,
  positive: positive,
  negative: negative
)

# But here the attribute limit is hardcoded
def get_receivables_by_seller(seller_id:, page: 1)
  path = "sellers/#{seller_id}/receivables?limit=1000&page=#{page}"
  response = @client.get(path: path, data: false)
  JSON.parse(response)
end
```

### Falta de padronização no retorno de erros

Como serão tratados os erros? Retorno nil, false, hash?

## Instalação

Crie uma nova gem:

```bash
bundle gem example_api_client
```

> Caso necessário, instale a versão indicada do Ruby:

```bash
rbenv install 3.0.6
rbenv global 3.0.6
ruby -v
```

Edite o arquivo `example_api_client.gemspec` e preencha os campos que possuem a tag `TODO:`.

No arquivo `Rakefile` da gem criada, adicione:

```bash
require "drasil/tasks"
```

No arquivo `Gemfile`, adicione:

```ruby
gem "drasil", git: "git@github.com:rsv-ink/drasil.git"

group :test do
  gem "rspec"
  gem "webmock"
end
```

Para instalar as dependências, execute:

```bash
bundle install
```

Para gerar a estrutura de pastas do `drasil`, execute:

```bash
bundle exec rake drasil:install
```

## Agora chegou a hora de fazer as configurações da sua gem no arquivo:

```
exemple/drasil/lib/exemplo_api_client.rb
```

## Estrutura de pastas dos Clients

`lib/{nome_client}_api_client.rb` = este arquivo configura a biblioteca de cliente da API Zoop, especificando URLs, cabeçalhos, parsers e outras configurações importantes necessárias para interagir eficazmente o client. Ele também requer outros arquivos e bibliotecas para funcionar corretamente.

`lib/{nome_client}_api_client` = é a pasta raiz do client. Ela serve como o diretório principal onde as pastas serão estruturadas. Nesta pasta, você encontrará os principais arquivos e subdiretórios que compõem a estrutura da biblioteca.

`lib/{nome_client}_api_client/parsers` = contém módulos responsáveis por interpretar (parsear) as respostas do Client e transformá-las em formatos utilizáveis, como objetos ou dados estruturados, para facilitar o processamento no código do cliente. A gem já disponibiliza um template em `lib/{nome_client}_api_client/parsers/default_parser.rb`:

```rb
module ZoopApiClient
  module Parsers
    class DefaultParser < Drasil::Parser
      def parse
        data     = @response
        metadata = {}

        [data, metadata]
      end
    end
  end
end
```

`lib/{nome_client}_api_client/resources` = abriga módulos e classes que representam recursos específicos da API Client, permitindo a interação com esses recursos de forma conveniente e abstrata, exemplo: "seller.rb"

`{nome_client}_api_client/spec`= A pasta spec contém arquivos de teste que são usados para verificar se a biblioteca do cliente funciona corretamente.

`{nome_client}_api_client/spec/fixtures/{resource}` = é usada para armazenar arquivos de "fixtures" que contêm respostas predefinidas de requisições de teste. Essas respostas são usadas nos testes para simular as respostas da API Zoop de maneira controlada e previsível, permitindo que os testes verifiquem o comportamento da biblioteca de cliente em diferentes cenários sem depender das respostas reais da API em um ambiente de produção ou de teste ao vivo. Isso ajuda a garantir que os testes sejam consistentes e repetíveis.

`{nome_client}_api_client/spec/resources` = contém os testes propriamente ditos relacionados aos resources da biblioteca de cliente.

`{nome_client}_api_client/spec/support` = guardam os helpers para testes rspecs, exemplo: WebMock.

## Usos

### Erros

Quando a resposta da requisição não contém um status de sucesso, uma das exceções a seguir é lançado:

| Classe de Erro                     | Código de Status | Descrição                                                 |
| ---------------------------------- | ---------------- | --------------------------------------------------------- |
| `Drasil::BadRequestError`          | 400              | Requisição inválida.                                      |
| `Drasil::UnauthorizedError`        | 401              | Falha na autenticação ou falta de autorização.            |
| `Drasil::ForbiddenError`           | 403              | Acesso proibido ao recurso solicitado.                    |
| `Drasil::ResourceNotFound`         | 404              | O recurso solicitado não foi encontrado.                  |
| `Drasil::ProxyAuthError`           | 407              | Falha na autenticação de proxy.                           |
| `Drasil::RequestTimeoutError`      | 408              | A requisição atingiu o tempo limite.                      |
| `Drasil::ConflictError`            | 409              | Conflito com o estado atual do recurso.                   |
| `Drasil::UnprocessableEntityError` | 422              | A entidade enviada na requisição não pode ser processada. |
| `Drasil::TimeoutError`             | -                | Erro de tempo limite genérico.                            |
| `Drasil::NilStatusError`           | -                | Resposta com status nulo.                                 |
| `Drasil::ConnectionFailed`         | -                | Falha na conexão com o servidor.                          |
| `Drasil::SSLError`                 | -                | Erro de SSL/TLS na conexão.                               |
| `Drasil::ParsingError`             | -                | Erro ao analisar a resposta.                              |

### Paginação

Os resources podem ser paginados utilizando os métodos de classe `page` e `per_page`. Segue o exemplo:

```ruby
sellers = ZoopApiClient::Seller.all.page(2).per_page(10)
```

Segundo o exemplo acima, uma requisição será feita para a rota `/sellers?page=2&limit=10`. A seguir, temos a documentação dos métodos relacionados à paginação:

| Método       | Descrição                                          |
| ------------ | -------------------------------------------------- |
| total_pages  | Retorna o total de páginas disponíveis             |
| next_page?   | Retorna true se houver mais páginas na API externa |
| current_page | Retorna o número da página atual                   |

### Criação de parsers

Os parsers são as classes responsáveis por mapear a resposta de uma API externa para o padrão esperado pela `drasil`. Eles herdam da classe `Drasil::Parser`.

> Um mesmo parser pode ser utilizado para rotas diferentes. Um novo parser deve ser criado sempre que não houver nenhum parser capaz de tratar a resposta de uma nova rota.

#### Exemplos de parsers

##### Quando a resposta da API é uma coleção

```json
{
  "data": [
    {
      "id": 1,
      "first_name": "John",
      "last_name": "Doe"
    }
  ],
  "info": {
    "pages_count": 10,
    "current_page": 1
  }
}
```

```ruby
class Parser < Drasil::Parser
  def parser
    data = @response[:data]
    metadata = {
      total_pages: @response[:info][:pages_count],
      page: @response[:info][:current_page]
    }

    return [data, metadata]
  end
end
```

##### Quando a resposta da API é um único resource

```json
{
  {
    "id": 1,
    "first_name": "John",
    "last_name": "Doe"
  }
}
```

```ruby
class Parser < Drasil::Parser
  def parser
    data = @response
    metadata = {}

    return [data, metadata]
  end
end
```

#### Passo a passo para criar um novo parser:

1. Crie uma classe, que herda da classe `Drasil::Parser`, na pasta `lib/{your_api_client}/parsers`.

```ruby
# lib/{your_api_client}/parsers/your_parser.rb
module YourApiClient
  module Parsers
    class YourParser
      def parse
        ...
      end
    end
  end
end
```

2. No método `Drasil.configure` no arquivo de entrada do seu API client adicione a seguinte linha:

```ruby
config.add_parser "/resource-path", YourApiClient::Parsers::YourParser
```

### Criação de resources

1. Crie um novo arquivo para o recurso: O nome do arquivo deve refletir o nome do recurso, por convenção em Ruby, deve estar em snake_case. Por exemplo, se você estiver criando um recurso para representar "vendedores" de uma API, pode nomear o arquivo como seller.rb.

2. Defina a classe do recurso: No arquivo que você criou, defina a classe do recurso, herdando de Drasil::Base. Isso estabelece uma base para a classe do recurso.

```rb
module ZoopApiClient
  class Seller < Drasil::Base
  end
end
```

3. Defina as associações: Use o método `has_one` ou `has_many` para definir as associações do recurso. Isso define como o recurso está relacionado a outros recursos na API.

```rb
class Seller < Drasil::Base
  has_one :resource, "/resources/:id"
  has_many :resources, "/resources"
end
```

4. Defina os atributos: Liste os atributos que pertencem a este recurso usando o método attributes. Esses atributos correspondem aos campos ou propriedades que você espera encontrar nas respostas da API relacionadas a este recurso.

```rb
class Seller < Drasil::Base
  has_one :resource, "/resources/:id"
  has_many :resources, "/resources"

  attributes :id, :name, :email, :created_at, :updated_at
end
```

5. Personalize os métodos, se necessário: Dependendo das necessidades específicas do recurso e da API, você pode adicionar métodos personalizados à classe do recurso para realizar ações específicas relacionadas a ele, como atualizações ou exclusões.

```rb
class Seller < Drasil::Base
  # ... outras definições de classe ...

  # https://api.zoop.ws/v1/marketplaces/{marketplace_id}/sellers/search
  # query_params:
  #   taxpayer_id
  #   ein
  def self.find_by_cpf_or_cnpj(cpf: nil, cnpj: nil)
    Seller.with(:search).where(taxpayer_id: cpf, ein: cnpj)
  end
end
```

## Testes

Para cada API Client devem ser construídos testes automatizados com a finalidade de garantir que todas as requisições e respostas estão sendo tratadas.
A seguir serão listados alguns pontos interessantes ao criar um teste de uma API.

### Simulação de resposta HTTP (Mock)

Durante os testes não devem ser realizados requisições para sites externos, dessa forma é preciso que as respostas sejam simuladas. Para fazer isso, utilizamos a gem _Webmock_ que bloqueia requisições para endpoints externos e permite a definição de um retorno específico.

Para criar simulações de resposta no teste basta utilizar o método helper _mock_request_. Através desse método é possível impedir que requisições sejam feitas para endpoints externos e o desenvolvedor defina uma resposta específica.

Ao utilizar o _mock_request_ são definidos dois parâmetros, o primeiro é o tipo de requisição (**:POST**, **:GET**, **:UPDATE**) e o segundo a _url_ do endpoint. Além disso, deve ser definido o retorno quando a requisição é feita, através do _.to_return_. Neste método, são passados o status da resposta e o body da resposta.

Observe que como body é passado um _json_ criado dentro da pasta `/spec/fixture`. Os bodys devem ser agrupados por tipo de resource e tenha por nome o status da resposta, como por exemplo "sellers/200.json".

A seguir é apresentado um código que faz a simulação de respostas quando é feito um método :GET para #{BASE_URL}//sellers/1234.

Nesse caso de teste, está sendo testado o método _find_ do resource Seller. São implementados duas simulações de resposta, uma para caso de seller encontrado e outra para o caso de recurso não encontrado.

```ruby
mock_request(:get, "/sellers/1234").to_return(status: 200, body: fixture("sellers/200.json"))
```

```ruby
require "spec_helper"

RSpec.describe ZoopApiClient::Seller do
  describe "#find" do
    context "when seller exists" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 200, body: fixture("sellers/200.json"))
      end
			...
    end

    context "when seller does not exist" do
      before do
        mock_request(:get, "/sellers/1234")
          .to_return(status: 404, body: fixture("sellers/404.json"))
      end
			...
    end
  end
end
```

### Testar todos os possíveis retornos para cada resource

Além de realizar a simulação de respostas é importante testar todos os possíveis tipos de retornos. Por exemplo, para o método find do resource seller.

```ruby
require "spec_helper"

RSpec.describe ZoopApiClient::Seller do
  describe "#find" do
    context "when seller exists" do
      ...
    end

    context "when seller does not exist" do
      ...
    end
  end
end
```

### Validação de respostas

Além do que foi descrito antes, também é interessante realmente validar as respostas esperadas. Como por exemplo, a validação do tipo de status retornado e os valores retornados. Para auxiliar neste último existe um método helper que compara os atributos do resources com a fixture definida na resposta da definição.

```ruby
require "spec_helper"

RSpec.describe ZoopApiClient::Seller do
  describe "#find" do
    context "when seller exists" do
      it { expect(subject).to be_a(ZoopApiClient::Seller) }
      it { expect(subject.attributes).to match_fixture("sellers/200.json") }
    end

    context "when seller does not exist" do
      it { expect { subject }.to raise_error(Faraday::ResourceNotFound) }
    end
  end
end
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
