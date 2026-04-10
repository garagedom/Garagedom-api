# Story 1.2: Registro de Usuário com E-mail e Senha

Status: review

## Story

Como visitante,
quero criar uma conta com e-mail e senha aceitando os termos de uso,
para que eu possa acessar a plataforma GarageDom.

## Acceptance Criteria

1. **[SUCESSO]** `POST /api/v1/auth/register` com `email`, `password`, `password_confirmation` válidos e `terms_accepted: true`
   - Cria usuário com senha criptografada (bcrypt via Devise)
   - Retorna HTTP 201 com JWT token no header `Authorization: Bearer <token>` e no body `{ token:, user: { id:, email: } }`

2. **[TERMOS]** `terms_accepted: false` (ou ausente)
   - HTTP 422 com `{ error: "Termos de uso devem ser aceitos", code: "terms_required" }`

3. **[EMAIL_DUPLICADO]** E-mail já cadastrado
   - HTTP 422 com `{ error: "E-mail já cadastrado", code: "email_taken" }`

4. **[VALIDAÇÃO]** Campos obrigatórios ausentes ou senha com menos de 8 caracteres
   - HTTP 422 com `{ error: "<mensagem>", code: "unprocessable_entity" }`

## Tasks / Subtasks

- [x] **Task 1: Implementar RegistrationsController#create** (AC: #1, #2, #3, #4)
  - [x] Substituir stub vazio por implementação completa
  - [x] Usar `build_resource(sign_up_params)` + `resource.save`
  - [x] Se persistido: gerar JWT via `Warden::JWTAuth::UserEncoder.new.call(resource, :user, nil)`
  - [x] Setar `response.headers["Authorization"] = "Bearer #{token}"`
  - [x] Renderizar `{ token:, user: { id:, email: } }` com status 201
  - [x] Se falhou: chamar `render_registration_errors`

- [x] **Task 2: Implementar sign_up_params** (AC: #1)
  - [x] Sobrescrever `sign_up_params` privado
  - [x] Permitir: `email`, `password`, `password_confirmation`, `terms_accepted`

- [x] **Task 3: Implementar render de erros por código específico** (AC: #2, #3, #4)
  - [x] `terms_accepted` errors → `{ error: "Termos de uso devem ser aceitos", code: "terms_required" }`
  - [x] `email` com "taken" → `{ error: "E-mail já cadastrado", code: "email_taken" }`
  - [x] Outros → `{ error: resource.errors.full_messages.first, code: "unprocessable_entity" }`
  - [x] Todos retornam HTTP 422

- [x] **Task 4: Escrever testes** (AC: #1, #2, #3, #4)
  - [x] Registro bem-sucedido: 201, JWT no header e body, user no DB
  - [x] terms_accepted false: 422 + code "terms_required"
  - [x] email duplicado: 422 + code "email_taken"
  - [x] senha curta: 422 + code "unprocessable_entity"
  - [x] email ausente: 422

## Dev Notes

### Estado da Story Anterior (1.1 — Implementada)

Verificado em 2026-04-09. O seguinte já existe:

**`app/models/user.rb`:**
```ruby
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: self

  validates :terms_accepted, acceptance: { message: :terms_required }, on: :create
end
```

**`app/controllers/api/v1/registrations_controller.rb`** (stub atual):
```ruby
module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json
    end
  end
end
```

**`config/routes.rb`** — rota já configurada:
- `POST /api/v1/auth/register` → `api/v1/registrations#create`

**`config/initializers/devise.rb`** — dispatch_requests atual:
```ruby
jwt.dispatch_requests = [["POST", %r{^/api/v1/auth/login$}]]
```
**NÃO adicionar registro ao dispatch_requests** — o JWT será gerado manualmente no controller.

**`app/controllers/api/v1/application_controller.rb`:**
- Herança correta: todos os controllers de feature herdam de `Api::V1::ApplicationController`
- **EXCEÇÃO:** `RegistrationsController` herda de `Devise::RegistrationsController` — isso é correto e esperado. NÃO mudar essa herança.

### Implementação do Controller — Padrão Correto

```ruby
module Api
  module V1
    class RegistrationsController < Devise::RegistrationsController
      respond_to :json

      def create
        build_resource(sign_up_params)
        resource.save
        if resource.persisted?
          token, payload = Warden::JWTAuth::UserEncoder.new.call(resource, :user, nil)
          resource.on_jwt_dispatch(token, payload)  # OBRIGATÓRIO: atualiza jti no banco
          response.headers["Authorization"] = "Bearer #{token}"
          render json: { token: token, user: { id: resource.id, email: resource.email } },
                 status: :created
        else
          render_registration_errors
        end
      end

      private

      def sign_up_params
        params.require(:user).permit(:email, :password, :password_confirmation, :terms_accepted)
      end

      def render_registration_errors
        if resource.errors[:terms_accepted].present?
          render json: { error: "Termos de uso devem ser aceitos", code: "terms_required" },
                 status: :unprocessable_entity
        elsif resource.errors[:email].any? { |e| e.include?("taken") }
          render json: { error: "E-mail já cadastrado", code: "email_taken" },
                 status: :unprocessable_entity
        else
          render json: { error: resource.errors.full_messages.first, code: "unprocessable_entity" },
                 status: :unprocessable_entity
        end
      end
    end
  end
end
```

### Por que `resource.on_jwt_dispatch(token, payload)` é obrigatório

O `JTIMatcher` (incluso no User) valida tokens comparando o `jti` do token com a coluna `jti` da tabela `users`. Se `on_jwt_dispatch` não for chamado:
- A coluna `jti` fica como `""` (default da migration)
- Qualquer request autenticado com o token retornará 401 porque o JTI não bate
- O `Warden::JWTAuth::UserEncoder.new.call` gera o token mas NÃO atualiza o DB sozinho
- Apenas o middleware de dispatch (para requests no `dispatch_requests`) atualiza automaticamente
- Como registro não está no `dispatch_requests`, o update manual é obrigatório

### Por que NÃO adicionar registro ao `dispatch_requests`

O middleware `TokenDispatcher` rodaria APÓS o controller renderizar a resposta. O token estaria no header mas **não no body** quando o `render` é chamado. Gerenciar o token manualmente no controller é mais explícito, testável e correto para este caso.

### Formato de Parâmetros Esperado

```json
{
  "user": {
    "email": "banda@example.com",
    "password": "minimo8chars",
    "password_confirmation": "minimo8chars",
    "terms_accepted": true
  }
}
```

O Devise usa o namespace `user` por padrão via `params.require(:user)`. O frontend deve enviar neste formato.

### Formato de Resposta Sucesso (201)

```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "user": {
    "id": 1,
    "email": "banda@example.com"
  }
}
```
Header: `Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...`

### Formato de Erros (422)

```json
{ "error": "Termos de uso devem ser aceitos", "code": "terms_required" }
{ "error": "E-mail já cadastrado", "code": "email_taken" }
{ "error": "Password is too short (minimum is 8 characters)", "code": "unprocessable_entity" }
```

### Regras Arquiteturais Obrigatórias

- **AR04:** Rota já está em `/api/v1/` — não mudar
- **AR05:** JWT retornado no header `Authorization: Bearer <token>` E no body
- **AR13:** Formato `{ error:, code: }` para todos os erros — já implementado
- **AR15:** `current_profile` não é usado nesta story (registro é pré-autenticação)

### Estrutura de Arquivos a Modificar

```
MODIFICAR:
  app/controllers/api/v1/registrations_controller.rb  # substituir stub pela implementação

CRIAR:
  test/controllers/api/v1/registrations_controller_test.rb
```

### Project Structure Notes

- O `RegistrationsController` herda de `Devise::RegistrationsController`, não de `Api::V1::ApplicationController`. Isso é correto — Devise exige essa herança para funcionar. O `before_action :authenticate_user!` do ApplicationController NÃO se aplica aqui (correto — registro é público).
- O helper `build_resource` é fornecido por `Devise::RegistrationsController`
- O helper `resource` referencia o objeto User em construção
- O helper `resource_name` retorna `:user`

### References

- Story 1.2 acceptance criteria: [Source: epics.md, Story 1.2]
- JWT no header Authorization: [Source: epics.md, AR05] [Source: architecture.md, Autenticação & Segurança]
- Formato de erro: [Source: epics.md, AR13]
- JTIMatcher on_jwt_dispatch: [Source: devise-jwt gem 0.13.0, RevocationStrategies::JTIMatcher]
- Warden::JWTAuth::UserEncoder: [Source: warden-jwt_auth gem]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- `on_jwt_dispatch` não existe no JTIMatcher desta versão (devise-jwt 0.13.0). O JTI é gerenciado por `before_create :initialize_jti` — o token gerado por `UserEncoder` usa o JTI já existente no user via `jwt_payload`. Nenhuma atualização manual necessária.
- Story documentava `on_jwt_dispatch` incorretamente — removido do controller e dos testes.

### Completion Notes List

- RegistrationsController#create implementado com `Warden::JWTAuth::UserEncoder`
- JWT retornado no header `Authorization: Bearer` e no body `{ token: }`
- Erros diferenciados: `terms_required`, `email_taken`, `unprocessable_entity`
- 10 testes de integração cobrindo todos os ACs
- 21/21 testes totais passando (sem regressões)

### File List

- app/controllers/api/v1/registrations_controller.rb
- test/controllers/api/v1/registrations_controller_test.rb
