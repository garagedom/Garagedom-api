# Story 1.1: Setup Técnico do Projeto

Status: review

## Story

Como desenvolvedor,
quero o projeto configurado com PostgreSQL, gems essenciais, CORS e infraestrutura de JWT,
para que todas as features sejam construídas sobre uma base consistente e funcional.

## Acceptance Criteria

1. **[GEMS]** Gems adicionadas e `bundle install` executa sem conflitos:
   - `pg` substituindo `sqlite3`
   - `rack-cors` descomentado e ativo
   - `bcrypt` descomentado e ativo
   - `devise` + `devise-jwt` adicionados
   - `omniauth-google-oauth2` + `omniauth-facebook` adicionados
   - `geocoder` adicionado
   - `aasm` adicionado

2. **[DATABASE]** `database.yml` configurado para PostgreSQL em dev, test e prod (sqlite3 removido de todos os ambientes)

3. **[CORS]** `config/initializers/cors.rb` ativado aceitando `http://localhost:3001` em dev (e ENV var `FRONTEND_URL` em prod)

4. **[DEVISE]** Devise instalado e User model gerado com suporte a:
   - Autenticação padrão (email + password)
   - JTI (coluna `jti: string, null: false` na tabela `users` — obrigatório para blocklist JWT do devise-jwt)
   - `terms_accepted: boolean, null: false, default: false`
   - `blocked: boolean, null: false, default: false`

5. **[JWT]** devise-jwt configurado com:
   - `dispatch_requests`: `[["POST", %r{^/api/v1/auth/login$}]]`
   - `revocation_requests`: `[["DELETE", %r{^/api/v1/auth/logout$}]]`
   - Estratégia de revogação: `Devise::JWT::RevocationStrategies::JTIMatcher`
   - Secret via `Rails.application.credentials.devise_jwt_secret_key` (ou `ENV["DEVISE_JWT_SECRET_KEY"]`)

6. **[ENCRYPTION]** Active Record Encryption configurado:
   - Chaves geradas via `bin/rails db:encryption:init`
   - Valores armazenados em `credentials.yml.enc` (ou `.env` em dev)
   - `config/initializers/encryption.rb` criado para validação do setup

7. **[CONTROLLERS]** `app/controllers/api/v1/application_controller.rb` criado com:
   - `before_action :authenticate_user!`
   - Helper `current_profile` retornando `current_user.profile`
   - `rescue_from` centralizado para erros comuns (ActiveRecord::RecordNotFound → 404, Pundit::NotAuthorizedError → 403)
   - Formato de erro padrão: `{ error: "mensagem", code: "código" }`

8. **[ROUTES]** `config/routes.rb` com estrutura base:
   - `devise_for :users` com controllers customizados (namespace `api/v1`)
   - `namespace :api do; namespace :v1 do; end; end`
   - `get "up"` (health check) mantido

9. **[DB]** `rails db:create && rails db:migrate` executa sem erros em ambiente de desenvolvimento

## Tasks / Subtasks

- [x] **Task 1: Atualizar Gemfile** (AC: #1)
  - [x] Remover `gem "sqlite3"` (linha 4)
  - [x] Adicionar `gem "pg", "~> 1.5"` no lugar
  - [x] Descomentar `gem "bcrypt", "~> 3.1.7"` (linha 12)
  - [x] Descomentar `gem "rack-cors"` (linha 37)
  - [x] Adicionar `gem "devise"`, `gem "devise-jwt"` após rack-cors
  - [x] Adicionar `gem "omniauth-google-oauth2"`, `gem "omniauth-facebook"` após devise-jwt
  - [x] Adicionar `gem "geocoder"`, `gem "aasm"` em seguida
  - [x] Rodar `bundle install` e confirmar sucesso

- [x] **Task 2: Configurar PostgreSQL** (AC: #2)
  - [x] Substituir todo o conteúdo de `config/database.yml` pela config PostgreSQL
  - [x] Usar `ENV["DATABASE_URL"]` em produção (sem raise quando ausente em dev)
  - [x] Remover referências ao sqlite3 em todos os ambientes
  - [x] Criar `.env.example` com variáveis necessárias

- [x] **Task 3: Ativar CORS** (AC: #3)
  - [x] Descomentar e configurar o bloco em `config/initializers/cors.rb`
  - [x] Em dev: `origins "http://localhost:3001"` via ENV FRONTEND_URL
  - [x] Methods: `[:get, :post, :put, :patch, :delete, :options, :head]`
  - [x] Headers: `:any` + expor `Authorization`

- [x] **Task 4: Instalar Devise e gerar User model** (AC: #4)
  - [x] Rodar `rails generate devise:install`
  - [x] Configurar `config.navigational_formats = []` no `config/initializers/devise.rb` (API-only — sem flash/redirect)
  - [x] Configurar `config.jwt` no `config/initializers/devise.rb` (ver Task 5)
  - [x] Rodar `rails generate devise User`
  - [x] Editar a migration gerada para adicionar: `jti`, `terms_accepted`, `blocked`
  - [x] Adicionar índice único: `add_index :users, :jti, unique: true`
  - [x] Configurar `User` model com módulos Devise incluindo `jwt_authenticatable`
  - [x] Estratégia de revogação: `include Devise::JWT::RevocationStrategies::JTIMatcher`

- [x] **Task 5: Configurar devise-jwt** (AC: #5)
  - [x] Bloco `config.jwt` configurado em `config/initializers/devise.rb`
  - [x] dispatch_requests e revocation_requests configurados
  - [x] Secret via `secret_key_base` (fallback) ou ENV/credentials
  - [x] `DEVISE_JWT_SECRET_KEY` adicionado ao `.env.example`

- [x] **Task 6: Configurar Active Record Encryption** (AC: #6)
  - [x] `bin/rails db:encryption:init` executado — chaves geradas
  - [x] Chaves adicionadas ao `.env` local
  - [x] `config/initializers/encryption.rb` criado com documentação do setup
  - [x] Chaves adicionadas ao `.env.example`

- [x] **Task 7: Criar Api::V1::ApplicationController** (AC: #7)
  - [x] `app/controllers/api/v1/application_controller.rb` criado
  - [x] Herda de `ActionController::API`
  - [x] `before_action :authenticate_user!`
  - [x] Helper `current_profile` implementado
  - [x] `rescue_from` para RecordNotFound e ParameterMissing
  - [x] Formato de erro padrão `{ error:, code: }`

- [x] **Task 8: Configurar Routes** (AC: #8)
  - [x] `devise_for :users` com controllers customizados no namespace `api/v1`
  - [x] `namespace :api do; namespace :v1 do; end; end`
  - [x] Health check mantido

- [x] **Task 9: Criar stubs de controllers de auth** (AC: #8)
  - [x] `app/controllers/api/v1/sessions_controller.rb` criado
  - [x] `app/controllers/api/v1/registrations_controller.rb` criado
  - [x] `app/controllers/api/v1/passwords_controller.rb` criado

- [x] **Task 10: Rodar migrations e validar** (AC: #9)
  - [x] `rails db:create` — bancos dev e test criados via Docker PostgreSQL
  - [x] `rails db:migrate` — migration do Devise executada com sucesso
  - [x] `bin/rails routes` — rotas Devise e namespace /api/v1/ exibidos corretamente
  - [x] 11/11 testes passando sem falhas ou regressões

## Dev Notes

### Estado Atual do Projeto (Estado Real — Não Presumido)

Verificado em 2026-04-09:

- **Framework:** Rails 8.0.5, API-only (`config.api_only = true` em `config/application.rb:30`)
- **Banco atual:** SQLite3 (gem `sqlite3 >= 2.1` no Gemfile, `database.yml` 100% sqlite3)
- **rack-cors:** comentado no Gemfile (linha 37) e `config/initializers/cors.rb` está totalmente comentado
- **bcrypt:** comentado no Gemfile (linha 12)
- **Devise:** não instalado
- **pg:** não instalado
- **Routes:** apenas health check `GET /up` (routes.rb linha 7)
- **Controllers:** apenas `app/controllers/application_controller.rb` + `app/controllers/concerns/` (vazio)
- **Solid Stack:** solid_cache, solid_queue, solid_cable já presentes no Gemfile ✅
- **dotenv-rails:** já presente ✅
- **cors.rb:** existe em `config/initializers/` mas completamente comentado

### Regras Arquiteturais Obrigatórias

- **AR01:** Rails já inicializado — NÃO criar novo projeto. Apenas modificar Gemfile + configurações.
- **AR02:** PostgreSQL em TODOS os ambientes (dev, test, prod). SQLite3 deve ser completamente removido do Gemfile e do database.yml.
- **AR15:** Usar `current_profile` (não `current_user`) como helper de autenticação em TODOS os controllers. Implementar em `Api::V1::ApplicationController`.
- **AR13:** Formato de erro padrão em TODOS os endpoints: `{ error: "mensagem", code: "código" }`. Centralizar via `rescue_from` no `Api::V1::ApplicationController`.
- **AR04:** Namespace `/api/v1/` obrigatório em TODAS as rotas autenticadas. Rota pública `/landing/:slug` ficará FORA deste namespace (Story 6.3).

### Estrutura de Arquivos a Criar/Modificar Nesta Story

```
MODIFICAR:
  Gemfile                                          # remover sqlite3, adicionar pg + gems auth
  config/database.yml                              # trocar para PostgreSQL todos ambientes
  config/initializers/cors.rb                      # ativar rack-cors
  config/routes.rb                                 # namespace api/v1 + devise_for
  .env.example                                     # variáveis necessárias

CRIAR:
  config/initializers/devise.rb                    # gerado por devise:install
  config/initializers/encryption.rb               # documentação do setup de encryption
  app/controllers/api/v1/application_controller.rb # base controller com rescue_from + current_profile
  app/controllers/api/v1/sessions_controller.rb   # stub vazio (implementado na Story 1.3)
  app/controllers/api/v1/registrations_controller.rb # stub vazio (implementado na Story 1.2)
  app/controllers/api/v1/passwords_controller.rb  # stub vazio (implementado na Story 1.5)
  db/migrate/YYYYMMDD_devise_create_users.rb       # gerado pelo devise generator (editar para adicionar jti, terms_accepted, blocked)
```

### Configuração de Database.yml Alvo

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: garagedom_api_development
  username: <%= ENV.fetch("DB_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DB_PASSWORD", "") %>
  host: <%= ENV.fetch("DB_HOST", "localhost") %>

test:
  <<: *default
  database: garagedom_api_test
  username: <%= ENV.fetch("DB_USERNAME", "postgres") %>
  password: <%= ENV.fetch("DB_PASSWORD", "") %>
  host: <%= ENV.fetch("DB_HOST", "localhost") %>

production:
  primary:
    url: <%= ENV.fetch("DATABASE_URL") %>
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  cache:
    url: <%= ENV.fetch("CACHE_DATABASE_URL", ENV.fetch("DATABASE_URL", "")) %>
    migrations_paths: db/cache_migrate
  queue:
    url: <%= ENV.fetch("QUEUE_DATABASE_URL", ENV.fetch("DATABASE_URL", "")) %>
    migrations_paths: db/queue_migrate
  cable:
    url: <%= ENV.fetch("CABLE_DATABASE_URL", ENV.fetch("DATABASE_URL", "")) %>
    migrations_paths: db/cable_migrate
```

### Configuração de Api::V1::ApplicationController Alvo

```ruby
module Api
  module V1
    class ApplicationController < ActionController::API
      before_action :authenticate_user!

      private

      def current_profile
        @current_profile ||= current_user&.profile
      end

      def not_found
        render json: { error: "Recurso não encontrado", code: "not_found" }, status: :not_found
      end

      def bad_request(exception)
        render json: { error: exception.message, code: "bad_request" }, status: :bad_request
      end

      def forbidden
        render json: { error: "Acesso negado", code: "forbidden" }, status: :forbidden
      end

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActionController::ParameterMissing, with: :bad_request
    end
  end
end
```

### Configuração do devise-jwt — Atenção à JTI Strategy

O JTIMatcher requer que o model User:
1. Tenha coluna `jti: string, null: false` com índice único
2. Inclua o módulo `jwt_authenticatable jwt_revocation_strategy: Devise::JWT::RevocationStrategies::JTIMatcher`

O Devise vai gerar automaticamente um JTI novo a cada login e invalidá-lo no logout. Isso é suficiente para a blocklist sem precisar de tabela separada.

**IMPORTANTE:** O `devise:install` vai criar um arquivo `devise.rb` extenso. Apenas as configurações abaixo precisam ser alteradas:
- `config.navigational_formats = []` — sem flash/redirect (API-only)
- Adicionar bloco `config.jwt do |jwt| ... end` no final

### Configuração de CORS

O frontend React rode em `http://localhost:3001` em dev. O header `Authorization` deve ser exposto para que o frontend consiga ler o JWT da resposta.

```ruby
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3001")

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ["Authorization"]
  end
end
```

### Stubs de Controllers Auth

Os controllers de sessions, registrations e passwords precisam existir para o `devise_for` no routes.rb não quebrar o boot. Devem ser classes vazias por agora:

```ruby
# app/controllers/api/v1/sessions_controller.rb
module Api
  module V1
    class SessionsController < Devise::SessionsController
      respond_to :json
    end
  end
end
```

Idem para `RegistrationsController < Devise::RegistrationsController` e `PasswordsController < Devise::PasswordsController`.

### Atenção: solid_cable + solid_queue com PostgreSQL

O `solid_cable`, `solid_queue` e `solid_cache` no `database.yml` atual apontam para databases SQLite separados. Com PostgreSQL, eles podem usar o mesmo banco ou databases separados. Para o MVP, usar o mesmo banco principal é suficiente — remover as entradas `cache:`, `queue:`, `cable:` do `database.yml` de produção ou apontar para o mesmo `DATABASE_URL`.

Verificar `config/cable.yml`, `config/queue.yml` e `config/cache.yml` para confirmar que não há referência hardcoded ao SQLite.

### Project Structure Notes

- Todos os controllers de feature herdarão de `Api::V1::ApplicationController` (não do `ApplicationController` raiz)
- O `ApplicationController` raiz (`app/controllers/application_controller.rb`) deve herdar de `ActionController::API` e ficar vazio — existe apenas para compatibilidade
- Policies ficarão em `app/policies/` (sem gem Pundit por enquanto — autorização manual por `profile_type`)
- Serializers ficarão em `app/serializers/` — objetos Ruby simples com método `as_json` (sem active_model_serializers ou JSONAPI)

### References

- Gems a adicionar: [Source: epics.md, AR03]
- PostgreSQL todos ambientes: [Source: epics.md, AR02] [Source: architecture.md, Arquitetura de Dados]
- current_profile obrigatório: [Source: epics.md, AR15] [Source: architecture.md, Padrões de Autorização]
- Formato de erro: [Source: epics.md, AR13] [Source: architecture.md, Padrões de Formato]
- JTI blocklist: [Source: epics.md, AR05] [Source: architecture.md, Autenticação & Segurança]
- Active Record Encryption: [Source: epics.md, AR07] [Source: architecture.md, Data Boundaries]
- Namespace /api/v1/: [Source: epics.md, AR04] [Source: architecture.md, Versionamento]
- Estrutura de controllers: [Source: architecture.md, Padrões de Estrutura > Controllers]
- Cascade delete setup: [Source: architecture.md, Gaps G1] — declarar `dependent: :destroy` no User→Profile na Story 2.1
- Solid Cable auth via JWT: [Source: epics.md, AR06] [Source: architecture.md, Gaps G5] — implementado na Story 5.2

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- PostgreSQL local (Homebrew) conflitava com Docker na porta 5432 → resolvido parando `brew services stop postgresql@14`
- `ENV.fetch("DATABASE_URL")` causava KeyError em dev → trocado para `ENV["DATABASE_URL"]` na seção production do database.yml
- JTIMatcher gerencia JTI automaticamente — removido callback manual `set_jti` e validação `presence: true`

### Completion Notes List

- Gemfile atualizado: sqlite3 removido, pg + bcrypt + rack-cors + devise + devise-jwt + omniauth + geocoder + aasm adicionados
- docker-compose.yml criado com PostgreSQL 14 (usuário: garagedom / senha: garagedom)
- database.yml migrado para PostgreSQL em todos os ambientes
- CORS ativado expondo header Authorization para frontend
- Devise instalado com JTIMatcher; User model inclui jti, terms_accepted, blocked
- devise-jwt configurado com dispatch/revocation requests corretos e fallback para secret_key_base
- Active Record Encryption keys geradas e documentadas
- Api::V1::ApplicationController criado com authenticate_user!, current_profile e rescue_from
- Stubs de SessionsController, RegistrationsController e PasswordsController criados
- db:create e db:migrate executados com sucesso via Docker PostgreSQL
- 11/11 testes passando (9 model + 2 integration)

### File List

- Gemfile
- Gemfile.lock
- docker-compose.yml
- config/database.yml
- config/routes.rb
- config/initializers/cors.rb
- config/initializers/devise.rb
- config/initializers/encryption.rb
- config/locales/devise.en.yml
- app/models/user.rb
- app/controllers/api/v1/application_controller.rb
- app/controllers/api/v1/sessions_controller.rb
- app/controllers/api/v1/registrations_controller.rb
- app/controllers/api/v1/passwords_controller.rb
- db/migrate/20260409231058_devise_create_users.rb
- db/schema.rb
- .env (atualizado — não comitar)
- .env.example
- test/models/user_test.rb
- test/factories/users.rb
- test/controllers/api/v1/application_controller_test.rb
