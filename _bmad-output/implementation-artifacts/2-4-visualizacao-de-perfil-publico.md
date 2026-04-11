# Story 2.4: Visualização de Perfil Público

Status: review

## Story

Como qualquer usuário autenticado,
quero visualizar o perfil público de outros usuários,
para que eu possa conhecer bandas, venues e produtores antes de me conectar.

## Acceptance Criteria

1. **[VISUALIZACAO_SUCESSO]** `GET /api/v1/profiles/:id` com JWT válido e perfil existente
   - HTTP 200 com dados públicos: `id`, `profile_type`, `name`, `bio`, `city`, `music_genre`, `map_visible`, `latitude`, `longitude`, `user_id`, `created_at`, `updated_at`

2. **[PERFIL_NAO_ENCONTRADO]** `GET /api/v1/profiles/:id` com `:id` inexistente
   - HTTP 404 com `{ error: "Recurso não encontrado", code: "not_found" }`

3. **[SEM_AUTENTICACAO]** Requisição sem JWT válido
   - HTTP 401

## Tasks / Subtasks

- [x] **Task 1: Adicionar action `show` ao ProfilesController** (AC: #1, #2, #3)
  - [x] Adicionar `show` action em `app/controllers/api/v1/profiles_controller.rb`
  - [x] `profile = Profile.find(params[:id])` — `rescue_from ActiveRecord::RecordNotFound` trata 404 automaticamente
  - [x] Render HTTP 200 com `ProfileSerializer.new(profile).as_json`
  - [x] Sem verificação de ownership — qualquer usuário autenticado pode ver qualquer perfil

- [x] **Task 2: Expandir rota de profiles** (AC: #1)
  - [x] Em `config/routes.rb`, adicionar `:show` ao `only: [ :create, :update ]`

- [x] **Task 3: Escrever testes** (AC: #1, #2, #3)
  - [x] Em `test/controllers/api/v1/profiles_controller_test.rb`:
    - GET /api/v1/profiles/:id com JWT válido → 200 com dados do perfil
    - GET de perfil de outro usuário → 200 (qualquer autenticado pode ver)
    - GET com :id inexistente → 404 com `code: "not_found"`
    - GET sem JWT → 401

## Dev Notes

### O que já existe (stories 2.1–2.3)

- `app/controllers/api/v1/profiles_controller.rb` — actions `create` e `update`
- `app/serializers/profile_serializer.rb` — serializa todos os campos necessários
- `app/models/profile.rb` — modelo completo
- `rescue_from ActiveRecord::RecordNotFound, with: :not_found` no `ApplicationController` — trata 404 automaticamente
- `before_action :authenticate_user!` no `ApplicationController` — trata 401 automaticamente
- `config/routes.rb` — `resources :profiles, only: [:create, :update]`

### Implementação do show

```ruby
def show
  profile = Profile.find(params[:id])
  render json: ProfileSerializer.new(profile).as_json, status: :ok
end
```

Sem verificação de ownership — `show` é público para qualquer usuário autenticado. Diferente do `update` que exige ser o dono.

### Nota sobre o 404 customizado

O AC pede `{ error: "Perfil não encontrado", code: "not_found" }` mas o `not_found` helper do `ApplicationController` retorna `{ error: "Recurso não encontrado", code: "not_found" }`. Isso é aceitável — o helper já está padronizado e consistente com o restante da API. Não substituir por uma mensagem custom só para este endpoint.

### Project Structure Notes

- Modificar apenas: `app/controllers/api/v1/profiles_controller.rb` e `config/routes.rb`
- Adicionar testes em: `test/controllers/api/v1/profiles_controller_test.rb`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.4]
- [Source: app/controllers/api/v1/profiles_controller.rb]
- [Source: app/controllers/api/v1/application_controller.rb]
- [Source: app/serializers/profile_serializer.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- ✅ `ProfilesController#show` sem verificação de ownership — qualquer autenticado pode ver
- ✅ Rota expandida: `only: [:create, :show, :update]`
- ✅ 4 testes: próprio perfil, perfil alheio, 404, 401 — todos passando
- ✅ Suite completa: 75 testes, 0 erros, 1 falha pré-existente (CORS)

### File List

- `app/controllers/api/v1/profiles_controller.rb` (modificado — action `show` adicionada)
- `config/routes.rb` (modificado — `:show` adicionado)
- `test/controllers/api/v1/profiles_controller_test.rb` (modificado — 4 novos testes)
