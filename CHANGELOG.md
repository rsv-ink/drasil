# Changelog

Todas as mudanças notáveis neste projeto serão documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
e este projeto adere ao [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-03-09

### 🎉 Mudanças Importantes

Esta versão introduz uma **arquitetura baseada em cliente**, abandonando o padrão singleton global para suportar múltiplos clientes de API simultaneamente. Esta é uma grande melhoria arquitetural que habilita multi-tenancy, thread-safety e a capacidade de usar diferentes versões de API lado a lado.

### ✨ Adicionado

#### Componentes Principais

- **`Drasil::Client`** - Nova classe principal de cliente para criar instâncias isoladas de cliente de API
  - Suporta múltiplas conexões simultâneas a diferentes APIs
  - Cada cliente possui sua própria configuração, conexão e registro de recursos isolados
  - Thread-safe por design, sem estado global compartilhado
  - Exemplo: `client = Drasil::Client.new(base_url: "https://api.example.com")`

- **`Drasil::Configuration`** - Classe de configuração baseada em instância (era baseada em módulo)
  - Cada cliente agora possui sua própria instância de configuração
  - Suporta todas as opções de configuração anteriores: `base_url`, `headers`, `ssl_options`, `proxy_options`, etc.
  - Novos métodos de instância: `add_parser`, `add_middleware`, `find_parser`, `parse`

- **`Drasil::ResourceRegistry`** - Novo sistema de gerenciamento de recursos
  - Registra recursos dinamicamente por cliente
  - Cria classes de recurso com escopo vinculadas a clientes específicos
  - Registros de recursos isolados previnem conflitos entre clientes
  - Exemplo: `client.register_resource(:users, User, parser: UserParser, parser_path: "/users/*")`

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
- **Testes de Integração** - Cenários de múltiplos clientes totalmente testados
- **Testes de Retrocompatibilidade** - Garante que código v1.x ainda funciona
- **Testes de Thread-Safety** - Valida uso concorrente de clientes
- **Testes de Performance** - Benchmarks para validação de overhead

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

- Refatorada arquitetura principal de singleton para baseada em cliente
- Melhorada organização do código com nova separação de componentes
- Melhor tratamento de erros com classes de exceção customizadas
- Gerenciamento de configuração aprimorado com abordagem baseada em instância
- Stack de middleware mais limpa por cliente

### 🎯 Caminho de Migração

Para usuários atualizando da v1.x:

1. **Nenhuma ação imediata necessária** - Código v1.x funciona com avisos de descontinuação
2. **Recomendado**: Migrar para abordagem baseada em cliente para novo código
4. **Suporte**: Avisos de descontinuação incluem exemplos de migração

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
