# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-12

### 🎉 Mudanças Importantes

Esta versão introduz uma **arquitetura baseada em cliente**, abandonando o padrão singleton global para suportar múltiplos clientes de API simultaneamente. Esta é uma grande melhoria arquitetural que habilita multi-tenancy, thread-safety e a capacidade de usar diferentes versões de API lado a lado.

### 📋 Sumário Executivo

**O que mudou:**
- ✅ Nova classe `Drasil::Client` para criar instâncias isoladas de clientes de API
- ✅ Suporte a múltiplos clientes simultâneos com configurações independentes
- ✅ Arquitetura thread-safe sem estado global compartilhado
- ✅ `Drasil::Client::Context` unifica configuração, parsers e recursos em um só lugar
- ✅ `Drasil::ConfigResolver` implementa fallback inteligente de configuração
- ✅ CI/CD com GitHub Actions testando em Ruby 3.1, 3.2 e 3.3
- ✅ 109 testes passando com cobertura completa
- ✅ README completamente reescrito com guias e exemplos
- ⚠️ `Drasil.configure` agora deprecated (mas ainda funciona)

**Impacto de Breaking Changes:**
- ✅ **ZERO** - Código v1.x continua funcionando com avisos de descontinuação
- ✅ Migração gradual recomendada, mas não obrigatória
- ✅ Retrocompatibilidade total mantida


### ✨ Adicionado

#### Componentes Principais

- **`Drasil::Client`** - Classe principal para criar instâncias isoladas de clientes de API
  - Suporta múltiplos clientes simultâneos com configurações independentes
  - Cada cliente possui seu próprio contexto, parsers, middlewares e recursos
  - Thread-safe através de isolamento de estado por instância
  - Suporte a configuração via parâmetros ou bloco de configuração

- **`Drasil::Client::Context`** - Contexto unificado do cliente
  - Gerencia configuração, parsers, middlewares e registro de recursos
  - Substitui a abordagem anterior com `Configuration` e `ResourceRegistry` separados
  - API simplificada e mais coesa para gerenciamento de componentes do cliente
  - Métodos: `add_parser`, `add_middleware`, `register_resource`, `find_parser`

- **`Drasil::ConfigResolver`** - Resolvedor de configuração com fallback
  - Implementa cadeia de precedência: cliente → global → padrão
  - Garante retrocompatibilidade com configuração global
  - Encapsula lógica de resolução de configuração em um único local

#### Classes de Erro

- **`Drasil::ParserNotFoundError`** - Lançado quando nenhum parser é encontrado para um padrão de URL
- **`Drasil::ResourceNotFoundError`** - Lançado quando um recurso não é encontrado no registro

#### Funcionalidades

- **Suporte a Múltiplos Clientes** - Execute múltiplos clientes de API simultaneamente
  ```ruby
  zoop = Drasil::Client.new(base_url: "https://api.zoop.com")
  shopify = Drasil::Client.new(base_url: "https://mystore.myshopify.com")
  stripe = Drasil::Client.new(base_url: "https://api.stripe.com")
  ```

- **Suporte a Múltiplas Versões** - Use diferentes versões da mesma API lado a lado
  ```ruby
  api_v1 = Drasil::Client.new(base_url: "https://api.example.com/v1")
  api_v2 = Drasil::Client.new(base_url: "https://api.example.com/v2")
  ```

- **Multi-Tenancy Melhorado** - Cada tenant pode ter seu próprio cliente com credenciais isoladas
- **Arquitetura Thread-Safe** - Sem estado global compartilhado entre clientes
- **Melhor Testabilidade** - Mais fácil de testar com instâncias de cliente isoladas

### 🔄 Modificado

#### Mudanças Incompatíveis (com retrocompatibilidade)

- **`Drasil::Config`** - Permanece como singleton de nível de classe para retrocompatibilidade
  - Ainda funciona com `Drasil.configure`, mas agora mostra avisos de descontinuação

- **`Drasil::Base`** - Aprimorado para suportar operações conscientes de cliente
  - Adicionado atributo de classe `drasil_client`
  - Método `connection` agora verifica primeiro a conexão específica do cliente
  - Métodos `page()` e `per_page()` usam configuração do cliente quando disponível
  - Volta para configuração global para retrocompatibilidade
  - `include_root_in_json` agora respeita a configuração do cliente

- **`Drasil::JSONParser`** - Agora aceita injeção de cliente
  - Construtor modificado: `initialize(app, options = {})` onde `options[:client]` é o cliente opcional
  - Usa o registro de parsers do cliente quando disponível
  - Volta para `Config.parse` global para retrocompatibilidade
  - Tratamento de erros melhorado com `ParserNotFoundError`

#### Mudanças Não Incompatíveis

- **Documentação Melhorada** - README abrangente com exemplos para todas as funcionalidades
- **Mensagens de Erro Melhores** - Mensagens de erro mais descritivas com contexto útil
- **Organização do Código** - Melhor separação de responsabilidades com nova estrutura de componentes

### ⚠️ Descontinuado

- **`Drasil.configure`** - Método de configuração global
  - **Razão**: Padrão singleton não suporta múltiplos clientes ou thread-safety
  - **Migração**: Use `Drasil::Client.new` ao invés
  - **Aviso de Descontinuação**: Mostra instruções de migração detalhadas quando usado

  ```ruby
  # Descontinuado (v1.x)
  Drasil.configure do |config|
    config.base_url = "https://api.example.com"
  end

  # Nova abordagem (v2.0+)
  client = Drasil::Client.new(base_url: "https://api.example.com")
  ```

- **Padrão de uso global do `Drasil::Config`**
  - **Razão**: Estado global impede múltiplos clientes
  - **Migração**: Use configuração específica do cliente

### 🐛 Correções de Bugs

- Corrigidos problemas de thread-safety causados pelo padrão singleton global
- Corrigida poluição do registro de parsers entre testes
- Corrigidos problemas de compartilhamento de conexão quando múltiplos clientes de API eram necessários
- Resolvido `include_root_in_json` não sendo respeitado em alguns cenários

### 🚀 Performance

- Reduzida pegada de memória por instância de cliente
- Melhorado throughput de requisições com conexões isoladas
- Melhor gerenciamento de recursos com classes com escopo
- Eliminada sobrecarga de lookup de estado global em caminhos críticos

### 🚢 CI/CD

- **GitHub Actions Workflow** (`.github/workflows/ci.yml`)
  - Execução automática de testes em múltiplas versões do Ruby (3.1, 3.2, 3.3)
  - Validação de build em diferentes ambientes
  - Executado em pull requests e pushes para main
  - Garante qualidade do código antes de merge

### 📚 Documentação

- **Novo README** - Completamente reescrito com:
  - Guia de início rápido
  - Exemplos abrangentes para todas as funcionalidades
  - Guia de migração da v1.x para v2.0
  - Tópicos avançados: SSL/mTLS, proxies, paginação, tratamento de erros
  - Guia de testes com exemplos de WebMock
  - Recomendações de estrutura de projeto

- **CHANGELOG** - Adicionado este changelog abrangente
- **Documentação YARD** - Todas as APIs públicas documentadas com exemplos
- **Comentários de Código** - Melhorada documentação inline

### 🧪 Testes

- **109 Testes Passando** - Cobertura completa de testes para nova arquitetura

- **Testes de Integração** (`spec/integration/multi_client_spec.rb`)
  - Cenários completos de múltiplos clientes simultâneos
  - Validação de isolamento entre clientes
  - Testes de diferentes configurações coexistindo

- **Testes Unitários Organizados** (movidos para `spec/unit/`)
  - `spec/unit/drasil/client_spec.rb` - Testa inicialização e API do cliente
  - `spec/unit/drasil/client/context_spec.rb` - Testa gerenciamento de contexto
  - `spec/unit/drasil/config_spec.rb` - Testa configuração global (deprecated)
  - `spec/unit/errors/error_spec.rb` - Testa classes de erro
  - `spec/unit/drasil/url_matcher_spec.rb` - Testa matching de URLs

- **Helpers de Teste Reutilizáveis** (`spec/support/helpers/`)
  - `client_helper.rb` - Helpers para criação de clientes de teste
  - `stub_helper.rb` - Helpers para stubbing de requests HTTP

- **Shared Examples** (`spec/support/shared_examples/`)
  - `parser_behavior.rb` - Comportamento esperado de parsers
  - `resource_behavior.rb` - Comportamento esperado de recursos

- **Testes de Retrocompatibilidade** - Garante que código v1.x ainda funciona com avisos
- **Testes de Thread-Safety** - Valida uso concorrente de clientes
- **Mocking com WebMock** - Todos os testes HTTP mockados para rapidez e confiabilidade

### 💔 Mudanças Incompatíveis

**Nenhuma** - Apesar de ser uma versão major, a retrocompatibilidade é mantida através de uma camada de descontinuação. Todo código v1.x continua a funcionar com avisos de descontinuação.

### 📦 Dependências

Sem mudanças nas dependências de runtime:
- `spyke` - Ainda a fundação para interface similar ao ActiveRecord
- `multi_json` (~> 1.15) - Parsing de JSON
- `faraday` - Cliente HTTP (via dependência do spyke)

Dependências de desenvolvimento:
- **Adicionado** `webmock` - Para mocking de requisições HTTP em testes

### 🔧 Mudanças Internas

- **Refatoração Arquitetural Completa**: Migração de singleton para arquitetura baseada em cliente
  - Removida dependência de estado global compartilhado
  - Cada cliente mantém seu próprio estado isolado e conexão independente

- **Unificação de Componentes**: Consolidação de `Configuration` + `ResourceRegistry` em `Context`
  - Anteriormente: dois objetos separados gerenciando estado do cliente
  - Agora: classe `Context` unificada com responsabilidades coesas
  - Reduz complexidade e melhora manutenibilidade

- **ConfigResolver**: Nova abstração para resolução de configuração
  - Encapsula lógica de fallback: cliente → global → padrão
  - Facilita manutenção da retrocompatibilidade
  - Ponto único de verdade para resolução de config

- **Melhorias na Organização do Código**:
  - Separação clara entre componentes públicos e internos
  - Melhor hierarquia de diretórios (`client/` para componentes do cliente)
  - Tratamento de erros com classes de exceção customizadas e descritivas

- **Stack de Middleware Por Cliente**: Cada cliente gerencia sua própria stack de middleware
  - Elimina interferência entre clientes diferentes
  - Permite customização específica por cliente

### 🎯 Caminho de Migração

Para usuários atualizando da v1.x:

#### Passo 1: Atualização Segura
```bash
# Atualize a gem
bundle update drasil

# Rode seus testes - tudo deve continuar funcionando
bundle exec rspec
```

**Resultado**: Seu código v1.x continua funcionando com avisos de descontinuação nos logs.

#### Passo 2: Migração Gradual (Recomendado)

**Antes (v1.x - Descontinuado)**:
```ruby
# config/initializers/drasil.rb
Drasil.configure do |config|
  config.base_url = "https://api.example.com"
  config.headers = { "Authorization" => "Bearer token" }
end

# app/models/seller.rb
class Seller < Drasil::Base
  uri "sellers/:id"
end

# Uso
seller = Seller.find("123")
```

**Depois (v2.0 - Recomendado)**:
```ruby
# app/services/api_client.rb
class ApiClient
  def self.instance
    @instance ||= Drasil::Client.new(
      base_url: "https://api.example.com",
      headers: { "Authorization" => "Bearer token" }
    ).tap do |client|
      client.register_resource(:sellers, Seller,
                              parser: SellerParser,
                              parser_path: "/sellers/*")
    end
  end
end

# app/models/seller.rb
class Seller < Drasil::Base
  uri "sellers/:id"
end

# Uso
client = ApiClient.instance
seller = client.sellers.find("123")
```

#### Passo 3: Benefícios Adicionais

Após migrar, você pode aproveitar novos recursos:

```ruby
# Múltiplos clientes simultâneos
zoop_client = Drasil::Client.new(base_url: "https://api.zoop.com")
shopify_client = Drasil::Client.new(base_url: "https://mystore.myshopify.com")

# Diferentes versões da mesma API
api_v1 = Drasil::Client.new(base_url: "https://api.example.com/v1")
api_v2 = Drasil::Client.new(base_url: "https://api.example.com/v2")

# Multi-tenancy com clientes isolados
tenant_clients = tenants.map do |tenant|
  Drasil::Client.new(
    base_url: tenant.api_url,
    headers: { "X-Tenant-ID" => tenant.id }
  )
end
```

#### Passo 4: Cronograma de Suporte

- **v2.0.x**: Suporte completo para API v1.x com avisos de descontinuação
- **v2.x.x**: API v1.x continuará funcionando durante toda a série v2
- **v3.0.0**: API v1.x será removida (data a ser anunciada)

#### Recursos de Ajuda

- **Avisos de Descontinuação**: Incluem exemplos de código de migração
- **README**: Seção dedicada ao guia de migração
- **Testes**: Suite de testes de retrocompatibilidade garante que nada quebra

### 📝 Notas da Release

Esta é uma **release major** que representa uma evolução significativa da arquitetura do Drasil, mas foi projetada para ser **100% retrocompatível** com código v1.x.

**Por que uma versão major?**
- Introduz mudança arquitetural fundamental (singleton → client-based)
- Depreca API global `Drasil.configure`
- Estabelece nova direção para o futuro da gem

**Por que é seguro atualizar?**
- Todo código v1.x continua funcionando sem modificações
- Avisos de descontinuação são informativos, não bloqueantes
- Suite completa de testes de retrocompatibilidade
- Documentação abrangente de migração

**Próximos Passos:**
- Coletar feedback da comunidade sobre a nova API
- Melhorar documentação baseado em casos de uso reais
- Considerar features adicionais para v2.1.0 (cache, retry, circuit breaker)
- Planejar timeline de remoção da API v1.x (v3.0.0)

**Motivação:**
Esta refatoração foi motivada por necessidades reais de produção no ecossistema Reserva INK:
- Necessidade de múltiplos clientes de API rodando simultaneamente
- Problemas de thread-safety com singleton global
- Dificuldade em testar código com estado global compartilhado
- Requisitos de multi-tenancy com credenciais isoladas por tenant

---

## [1.0.2] - 2025-03-06

### 🐛 Correções de Bugs

- Adicionadas classes de resposta de erro ausentes (`ClientError` e `ServerError`)
- Adicionados testes para `ProxyAuthError` e `RequestTimeoutError`

### 📚 Documentação

- Melhorada documentação de tratamento de erros
- Adicionados exemplos para todas as classes de erro

---

## [1.0.1] - 2025-02-15

### ✨ Adicionado

- Suporte a configuração de proxy via `proxy_options`
- Suporte a configuração SSL/TLS via `ssl_options`
- Classes de erro abrangentes para todos os códigos de status HTTP

### 🐛 Correções de Bugs

- Corrigidos problemas de validação de certificado SSL
- Melhoradas mensagens de erro para falhas de conexão

### 📚 Documentação

- Adicionados exemplos de configuração SSL/TLS
- Adicionado guia de configuração de proxy
- Melhorada documentação de tratamento de erros

---

## [1.0.0] - 2025-01-10

### 🎉 Lançamento Inicial

- Interface similar ao ActiveRecord para clientes de API
- Construído sobre Spyke e Faraday
- Sistema de parser customizado para transformação de respostas
- Suporte a paginação
- Tratamento de erros para códigos de status HTTP
- Configuração global via `Drasil.configure`
- Utilitários de criação de recursos e parsers

### ✨ Funcionalidades

- `Drasil::Base` - Classe base para recursos de API
- `Drasil::Parser` - Classe base para parsers de resposta
- `Drasil::Config` - Singleton de configuração global
- Helpers de paginação: `page()`, `per_page()`, `total_pages`, `next_page?`
- Classes de erro abrangentes para códigos de status HTTP

### 📚 Documentação

- README inicial com instruções de configuração
- Guia de criação de parsers
- Guia de criação de recursos
- Guia de testes com WebMock

---

## Legenda

- 🎉 Mudanças Importantes
- ✨ Adicionado
- 🔄 Modificado
- ⚠️ Descontinuado
- 🐛 Correções de Bugs
- 🚀 Performance
- 📚 Documentação
- 🧪 Testes
- 💔 Mudanças Incompatíveis
- 🔧 Mudanças Internas

---

**Nota**: Para guias de migração detalhados e exemplos, consulte o [README](README.md).
