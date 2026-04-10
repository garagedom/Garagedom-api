# Story 1.5: Recuperação de Senha por E-mail

Status: review

## Story

Como usuário cadastrado,
quero solicitar redefinição de senha via e-mail,
para que eu possa recuperar o acesso à minha conta caso esqueça a senha.

## Acceptance Criteria

1. **[SOLICITA_RESET]** `POST /api/v1/auth/password` com e-mail cadastrado
   - E-mail de redefinição enviado (Devise mailer)
   - HTTP 200 com `{ message: "Se o e-mail estiver cadastrado, você receberá as instruções de recuperação" }`
   - **Mesmo response se e-mail NÃO existir** (previne enumeração de e-mails)

2. **[RESET_SUCESSO]** `PUT /api/v1/auth/password` com token válido e nova senha
   - Senha atualizada no banco
   - HTTP 200 com `{ message: "Senha redefinida com sucesso" }`

3. **[TOKEN_INVALIDO]** Token expirado ou inválido
   - HTTP 422 com `{ error: "Token inválido ou expirado", code: "invalid_reset_token" }`

## Tasks / Subtasks

- [x] **Task 1: Implementar PasswordsController#create** (AC: #1)
  - [x] Chamar `resource_class.send_reset_password_instructions(resource_params)` — Devise envia o e-mail
  - [x] Sempre retornar HTTP 200 independente do resultado (previne enumeração)
  - [x] `skip_before_action :verify_signed_out_user, raise: false`
  - [x] `respond_to :json`

- [x] **Task 2: Implementar PasswordsController#update** (AC: #2, #3)
  - [x] `resource_class.reset_password_by_token(resource_params)` retorna user com ou sem erros
  - [x] Se `resource.errors.empty?` → HTTP 200 com message
  - [x] Se erros → HTTP 422 com `{ error: "Token inválido ou expirado", code: "invalid_reset_token" }`
  - [x] **NÃO chamar** `sign_in` após o reset (API-only mode não usa sessão)

- [x] **Task 3: Implementar resource_params** (AC: #1, #2)
  - [x] `params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)`

- [x] **Task 4: Escrever testes** (AC: #1, #2, #3)
  - [x] `POST /api/v1/auth/password` com e-mail cadastrado → 200 + e-mail enviado (verifica `ActionMailer::Base.deliveries`)
  - [x] `POST /api/v1/auth/password` com e-mail NÃO cadastrado → 200 (sem enumeração)
  - [x] `PUT /api/v1/auth/password` com token válido → 200 + senha alterada (login com nova senha funciona)
  - [x] `PUT /api/v1/auth/password` com token inválido → 422 + code `invalid_reset_token`
  - [x] `PUT /api/v1/auth/password` com token expirado → 422 + code `invalid_reset_token`

## Dev Notes

### Estado das Stories Anteriores

**`app/controllers/api/v1/passwords_controller.rb`** atual (stub da Story 1.1):
```ruby
module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      respond_to :json
    end
  end
end
```

**Routes já configuradas (Story 1.1):**
- `POST /api/v1/auth/password` → `api/v1/passwords#create`
- `PUT /api/v1/auth/password` → `api/v1/passwords#update`

**User model** já tem `:recoverable` no `devise` call (Story 1.1). Nenhuma alteração no modelo necessária.

**Devise config** (`config/initializers/devise.rb`):
```ruby
config.reset_password_within = 6.hours
```

### Implementação do Controller

```ruby
module Api
  module V1
    class PasswordsController < Devise::PasswordsController
      respond_to :json

      # Necessário para API-only: Devise::PasswordsController herda de DeviseController
      # que tem verify_signed_out_user que chama respond_to (não existe em ActionController::API)
      skip_before_action :verify_signed_out_user, raise: false

      def create
        # Sempre tenta enviar — mas sempre retorna 200 independente do resultado
        # (previne enumeração de e-mails: não revela se o e-mail existe)
        resource_class.send_reset_password_instructions(resource_params)
        render json: { message: "Se o e-mail estiver cadastrado, você receberá as instruções de recuperação" },
               status: :ok
      end

      def update
        self.resource = resource_class.reset_password_by_token(resource_params)
        if resource.errors.empty?
          # NÃO chamar sign_in — API-only não usa sessão
          render json: { message: "Senha redefinida com sucesso" }, status: :ok
        else
          render json: { error: "Token inválido ou expirado", code: "invalid_reset_token" },
                 status: :unprocessable_entity
        end
      end

      private

      def resource_params
        params.require(:user).permit(:email, :password, :password_confirmation, :reset_password_token)
      end
    end
  end
end
```

### Padrão Correto: Sempre 200 no create

`send_reset_password_instructions` é uma **class method** de Devise que:
1. Busca o usuário pelo e-mail
2. Gera e armazena o token de reset
3. Envia o e-mail via ActionMailer

Se o e-mail não existir, retorna um User inválido com erros — mas **ignoramos esses erros** intencionalmente para prevenir enumeração. Sempre retornamos 200 com a mesma mensagem.

### Como Obter o Token em Testes

```ruby
# Método mais simples: send_reset_password_instructions na instância retorna o token raw
token = user.send_reset_password_instructions
# O token retornado é o raw token (antes do hash) — usar diretamente no PUT request

# PUT com token válido:
put "/api/v1/auth/password",
    params: { user: { reset_password_token: token, password: "nova_senha", password_confirmation: "nova_senha" } },
    as: :json
```

### Como Testar Token Expirado

```ruby
token = user.send_reset_password_instructions
# Forçar expiração: reset_password_within é 6 horas (devise.rb)
user.update!(reset_password_sent_at: 7.hours.ago)

put "/api/v1/auth/password",
    params: { user: { reset_password_token: token, password: "nova_senha", password_confirmation: "nova_senha" } },
    as: :json
# → 422 com invalid_reset_token
```

### Verificar E-mail Enviado em Testes

```ruby
# test/test_helper.rb já tem: config.action_mailer.delivery_method = :test
# Emails vão para ActionMailer::Base.deliveries

test "envia email de reset" do
  assert_difference "ActionMailer::Base.deliveries.size", 1 do
    post "/api/v1/auth/password", params: { user: { email: @user.email } }, as: :json
  end
  email = ActionMailer::Base.deliveries.last
  assert_equal [@user.email], email.to
end
```

**Limpar deliveries no setup:** `ActionMailer::Base.deliveries.clear` no `setup` do test.

### Formato de Parâmetros

**Solicitar reset (POST):**
```json
{ "user": { "email": "banda@example.com" } }
```

**Redefinir senha (PUT):**
```json
{
  "user": {
    "reset_password_token": "abc123...",
    "password": "nova_senha_segura",
    "password_confirmation": "nova_senha_segura"
  }
}
```

### Aprendizados das Stories 1.2–1.4

- `skip_before_action :verify_signed_out_user, raise: false` — obrigatório em TODOS os Devise controllers em API-only mode. Sem isso: `NoMethodError: undefined method 'respond_to'`
- **Nunca usar** `respond_with` — sempre `render json:`
- **Nunca usar** `authenticate_user!` antes do `destroy` em SessionsController (causa FailureApp que também usa `respond_to`) — padrão similar aqui: não chamar `sign_in` no update
- `params.require(:user)` para todos os endpoints de autenticação

### Estrutura de Arquivos

```
MODIFICAR:
  app/controllers/api/v1/passwords_controller.rb

CRIAR:
  test/controllers/api/v1/passwords_controller_test.rb
```

Nenhuma migration necessária — `:recoverable` já usa colunas existentes (`reset_password_token`, `reset_password_sent_at`) geradas pela migration do Devise (Story 1.1).

### References

- Story 1.5 acceptance criteria: [Source: epics.md, Story 1.5]
- AR13: Formato de erro `{ error:, code: }`: [Source: epics.md]
- Devise `:recoverable` token expiration: `config.reset_password_within = 6.hours` [Source: config/initializers/devise.rb]
- Aprendizados API-only Devise: [Source: stories 1.2, 1.3, 1.4 Dev Agent Record]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

Sem issues — implementação direta. O padrão `skip_before_action :verify_signed_out_user, raise: false` já estava documentado nas stories anteriores.

### Completion Notes List

- `PasswordsController#create` sempre retorna 200 independente de o e-mail existir (previne enumeração)
- `PasswordsController#update` usa `reset_password_by_token` do Devise; `resource.errors.empty?` distingue sucesso de falha
- `sign_in` NÃO é chamado após reset — API-only não usa sessão
- `user.send_reset_password_instructions` retorna o raw token para uso em testes
- `ActionMailer::Base.deliveries.clear` no `setup` e verificação de `deliveries.size` nos testes
- Token expirado: forçar `reset_password_sent_at: 7.hours.ago` (reset_password_within = 6 horas)
- 6 testes novos; 40/40 testes totais passando

### File List

- app/controllers/api/v1/passwords_controller.rb (modificado)
- test/controllers/api/v1/passwords_controller_test.rb (criado)
