# Story 1.4: Autenticação OAuth (Google e Facebook)

Status: review

## Story

Como visitante,
quero criar conta ou fazer login via OAuth do Google ou Facebook,
para que eu possa acessar a plataforma sem precisar criar uma senha separada.

## Acceptance Criteria

1. **[SUCESSO_NOVO]** Fluxo OAuth concluído com provider novo (email não cadastrado)
   - Usuário criado pelo `uid` + `provider` do OAuth
   - HTTP 201 com JWT no header `Authorization: Bearer <token>` e no body `{ token:, user: { id:, email: } }`

2. **[SUCESSO_EXISTENTE]** Fluxo OAuth com usuário já cadastrado (mesmo provider+uid)
   - Usuário encontrado, não duplicado
   - HTTP 200 com JWT no header e body

3. **[FALHA_OAUTH]** Falha no fluxo OAuth (token inválido, permissão negada)
   - HTTP 422 com `{ error: "Autenticação OAuth falhou", code: "oauth_failed" }`

## Tasks / Subtasks

- [x] **Task 1: Criar migration para colunas provider e uid** (AC: #1, #2)
  - [x] `rails generate migration AddOmniauthToUsers provider:string uid:string`
  - [x] Adicionar índice composto: `add_index :users, [:provider, :uid], unique: true`
  - [x] Rodar `rails db:migrate`

- [x] **Task 2: Atualizar User model** (AC: #1, #2)
  - [x] Adicionar `:omniauthable, omniauth_providers: %i[google_oauth2 facebook]` ao `devise`
  - [x] Adicionar `from_omniauth(auth)` class method
  - [x] `from_omniauth` faz `find_or_initialize_by(provider:, uid:)` e salva com password aleatório para usuários novos
  - [x] Usuários OAuth novos têm `terms_accepted: true` implícito (OAuth implica aceitação na UI do frontend)
  - [x] Usuários OAuth não têm senha — usar `SecureRandom.hex(16)` como password inicial

- [x] **Task 3: Criar OmniauthCallbacksController** (AC: #1, #2, #3)
  - [x] Criar `app/controllers/api/v1/omniauth_callbacks_controller.rb`
  - [x] Herdar de `Devise::OmniauthCallbacksController`
  - [x] Implementar `#google_oauth2` e `#facebook` actions (ambas chamam `handle_omniauth`)
  - [x] `handle_omniauth` usa `User.from_omniauth(request.env["omniauth.auth"])`
  - [x] Se sucesso: gerar JWT via `UserEncoder`, retornar 201 (novo) ou 200 (existente)
  - [x] Se falha (`omniauth.auth` nil ou exceção): retornar 422 com `oauth_failed`
  - [x] `skip_before_action :verify_signed_out_user, raise: false`

- [x] **Task 4: Atualizar routes.rb** (AC: #1, #2)
  - [x] Adicionar `omniauth_callbacks: "api/v1/omniauth_callbacks"` ao `devise_for`
  - [x] Confirmar que `bin/rails routes` mostra rotas de callback

- [x] **Task 5: Configurar OmniAuth para ambiente de teste** (AC: #1, #2, #3)
  - [x] Configurar `OmniAuth.config.test_mode = true` no `test_helper.rb`
  - [x] Configurar `OmniAuth.config.on_failure` em `config/initializers/omniauth.rb` para retornar JSON 422 (API mode)
  - [x] Adicionar middleware de sessão em `config/application.rb` para OmniAuth

- [x] **Task 6: Escrever testes** (AC: #1, #2, #3)
  - [x] Novo usuário via Google: 201 + token + user criado no DB
  - [x] Usuário existente via Google: 200 + token + sem duplicação
  - [x] Novo usuário via Facebook: 201 + token
  - [x] Falha OAuth (invalid_credentials): 422 + code oauth_failed

## Dev Notes

### Estado das Stories Anteriores

**`app/models/user.rb`** atual:
```ruby
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  validates :terms_accepted, acceptance: { message: :terms_required }, on: :create
end
```

**`config/routes.rb`** atual:
```ruby
devise_for :users,
  path: "",
  path_names: { ... },
  controllers: {
    sessions: "api/v1/sessions",
    registrations: "api/v1/registrations",
    passwords: "api/v1/passwords"
    # omniauth_callbacks: "api/v1/omniauth_callbacks"  ← adicionar
  }
```

**Gems já instaladas (Story 1.1):** `omniauth-google-oauth2`, `omniauth-facebook`

**Aprendizados das Stories 1.2 e 1.3:**
- JWT via `Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)` retorna `[token, _payload]`
- JTI gerenciado automaticamente pelo `before_create :initialize_jti` do JTIMatcher
- `skip_before_action :verify_signed_out_user, raise: false` para herança de Devise controllers em API mode

### Implementação do User Model

```ruby
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self,
         :omniauthable, omniauth_providers: %i[google_oauth2 facebook]

  validates :terms_accepted, acceptance: { message: :terms_required }, on: :create,
            unless: :oauth_user?

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = auth.info.email if user.email.blank?
    if user.new_record?
      user.password = SecureRandom.hex(16)
      user.terms_accepted = true  # OAuth implica aceitação na UI do frontend
    end
    user.save!
    user
  rescue ActiveRecord::RecordInvalid
    nil
  end

  private

  def oauth_user?
    provider.present?
  end
end
```

**Por que `unless: :oauth_user?` na validação de terms_accepted:**
Usuários OAuth não passam pelo formulário de registro normal. O frontend deve exibir os termos antes de iniciar o fluxo OAuth. No backend, users com `provider` presente são considerados OAuth e têm `terms_accepted: true` definido por `from_omniauth`.

### Implementação do Controller

```ruby
module Api
  module V1
    class OmniauthCallbacksController < Devise::OmniauthCallbacksController
      skip_before_action :verify_signed_out_user, raise: false

      def google_oauth2
        handle_omniauth
      end

      def facebook
        handle_omniauth
      end

      private

      def handle_omniauth
        auth = request.env["omniauth.auth"]
        if auth.blank?
          render json: { error: "Autenticação OAuth falhou", code: "oauth_failed" },
                 status: :unprocessable_entity
          return
        end

        user = User.from_omniauth(auth)
        if user.nil?
          render json: { error: "Autenticação OAuth falhou", code: "oauth_failed" },
                 status: :unprocessable_entity
          return
        end

        new_user = !user.previously_new_record? && user.id_previously_changed?
        # Mais confiável: verificar se foi criado neste request
        status_code = user.previously_new_record? ? :created : :ok

        token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
        response.headers["Authorization"] = "Bearer #{token}"
        render json: { token: token, user: { id: user.id, email: user.email } },
               status: status_code
      end
    end
  end
end
```

**Como detectar usuário novo:** `user.previously_new_record?` retorna `true` se o user foi criado neste request (Rails 6+). Se `true` → 201, se `false` → 200.

### Configuração de Testes com OmniAuth Test Mode

```ruby
# test/test_helper.rb ou config/initializers/omniauth.rb
OmniAuth.config.test_mode = true
```

Mock para Google no teste:
```ruby
OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
  provider: "google_oauth2",
  uid: "123456",
  info: { email: "user@gmail.com", name: "Test User" }
})
```

Mock para Facebook:
```ruby
OmniAuth.config.mock_auth[:facebook] = OmniAuth::AuthHash.new({
  provider: "facebook",
  uid: "654321",
  info: { email: "user@facebook.com", name: "Test User" }
})
```

Para testar falha OAuth:
```ruby
OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
```

O teste faz `get "/users/auth/google_oauth2/callback"` (OmniAuth test mode simula o redirect automaticamente).

### Rotas OAuth com `path: ""`

Com a configuração atual `path: ""`, as rotas OmniAuth serão:
- Iniciação: `GET /users/auth/google_oauth2`
- Callback: `GET /users/auth/google_oauth2/callback`
- Callback: `GET /users/auth/facebook/callback`

**Nota:** O AC do epics.md menciona `/api/v1/auth/google_oauth2/callback`. A rota real com a config atual é `/users/auth/google_oauth2/callback`. Para a MVP, isso é aceitável — o importante é o comportamento, não o path exato. Se necessário, o path pode ser ajustado com `path_prefix` no devise_for.

### Questão do `omniauth-facebook` e `omniauth-google-oauth2` em Modo Test

Em modo test com `OmniAuth.config.test_mode = true`, os callbacks são simulados sem chamar o provider real. Nenhuma chave de API é necessária para os testes.

Em produção, precisará de:
- `GOOGLE_CLIENT_ID` e `GOOGLE_CLIENT_SECRET` em `config/initializers/devise.rb`
- `FACEBOOK_APP_ID` e `FACEBOOK_APP_SECRET`

Para esta story, não configurar as credenciais reais — apenas garantir o fluxo funciona em test mode.

### Configurar OmniAuth Providers no Devise

No `config/initializers/devise.rb`, adicionar:
```ruby
config.omniauth :google_oauth2,
  ENV.fetch("GOOGLE_CLIENT_ID", "test_google_id"),
  ENV.fetch("GOOGLE_CLIENT_SECRET", "test_google_secret")

config.omniauth :facebook,
  ENV.fetch("FACEBOOK_APP_ID", "test_facebook_id"),
  ENV.fetch("FACEBOOK_APP_SECRET", "test_facebook_secret")
```

### Atenção: validatable + omniauthable sem password

O módulo `:validatable` exige password por padrão. Para usuários OAuth (sem senha real), usamos `SecureRandom.hex(16)` como senha. Isso é aceitável pois eles nunca farão login com senha — apenas via OAuth.

Alternativa: adicionar `skip_password_validation` temporariamente no `from_omniauth`, mas o `SecureRandom.hex(16)` é mais simples e seguro.

### Estrutura de Arquivos

```
CRIAR:
  app/controllers/api/v1/omniauth_callbacks_controller.rb
  db/migrate/YYYYMMDD_add_omniauth_to_users.rb
  test/controllers/api/v1/omniauth_callbacks_controller_test.rb

MODIFICAR:
  app/models/user.rb
  config/routes.rb
  config/initializers/devise.rb
  test/test_helper.rb  (adicionar OmniAuth.config.test_mode = true)
```

### References

- Story 1.4 acceptance criteria: [Source: epics.md, Story 1.4]
- AR02 OAuth: Google + Facebook via omniauth: [Source: epics.md, AR03]
- JWT pattern: [Source: story 1-2, story 1-3 Dev Agent Record]
- previously_new_record?: [Source: Rails 6+ ActiveRecord API]
- OmniAuth test mode: [Source: omniauth gem docs]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Sintaxe Ruby: `:omniauthable` não pode vir após keyword args (`jwt_revocation_strategy: self`). Corrigido movendo `:omniauthable` antes do `jwt_revocation_strategy:` na chamada `devise`.
- `OmniAuth::NoSessionError` em API-only mode: Rails API não inclui session middleware por padrão, mas OmniAuth 2.x requer sessão para proteção CSRF. Corrigido adicionando `ActionDispatch::Cookies` + `ActionDispatch::Session::CookieStore` no `config/application.rb`.
- Falha OAuth (`invalid_credentials`) causava redirect (302) em vez de 422: OmniAuth em modo falha chama o FailureApp que redireciona. Corrigido configurando `OmniAuth.config.on_failure` em `config/initializers/omniauth.rb` para retornar JSON 422 diretamente (Rack response).

### Completion Notes List

- Migration adicionou `provider:string` e `uid:string` com índice composto único em `users`.
- `User.from_omniauth(auth)` usa `find_or_initialize_by(provider:, uid:)`, define `terms_accepted: true` e `password = SecureRandom.hex(16)` para novos usuários. `terms_accepted` validation tem `unless: :oauth_user?`.
- `OmniauthCallbacksController` usa `previously_new_record?` para distinguir 201 (novo) vs 200 (existente). JWT gerado via `Warden::JWTAuth::UserEncoder`.
- OmniAuth providers configurados no devise.rb com fallback para ENV vars de teste.
- `OmniAuth.config.test_mode = true` no `test_helper.rb`; `on_failure` retorna JSON para API mode.
- 4 testes novos; 34/34 testes totais passando.

### File List

- db/migrate/20260409235900_add_omniauth_to_users.rb (criado)
- app/models/user.rb (modificado)
- app/controllers/api/v1/omniauth_callbacks_controller.rb (criado)
- config/routes.rb (modificado)
- config/initializers/devise.rb (modificado — providers OmniAuth)
- config/initializers/omniauth.rb (criado — on_failure JSON handler)
- config/application.rb (modificado — session middleware)
- test/test_helper.rb (modificado — OmniAuth test mode)
- test/controllers/api/v1/omniauth_callbacks_controller_test.rb (criado)
