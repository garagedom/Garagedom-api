# Story 2.2: Edição de Perfil

Status: review

## Story

Como usuário autenticado com perfil criado,
quero editar as informações do meu perfil (nome, bio, gênero musical, cidade),
para que minha apresentação na plataforma esteja sempre atualizada.

## Acceptance Criteria

1. **[EDICAO_SUCESSO_COM_CIDADE]** `PATCH /api/v1/profiles/:id` com JWT válido e `city` alterada
   - Novo `GeocodingJob` enfileirado para atualizar `latitude`/`longitude`
   - HTTP 200 com perfil atualizado

2. **[EDICAO_SUCESSO_SEM_CIDADE]** `PATCH /api/v1/profiles/:id` com JWT válido sem alterar `city`
   - Nenhum `GeocodingJob` enfileirado
   - HTTP 200 com perfil atualizado

3. **[OUTRO_USUARIO]** `PATCH /api/v1/profiles/:id` com JWT de outro usuário
   - HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

4. **[SEM_AUTENTICACAO]** Requisição sem JWT válido
   - HTTP 401

5. **[CAMPOS_INVALIDOS]** Campos com formato inválido (ex: `name` vazio, `profile_type` alterado)
   - HTTP 422 com detalhes do erro

6. **[PERFIL_NAO_ENCONTRADO]** `:id` inexistente
   - HTTP 404 com `{ error: "Recurso não encontrado", code: "not_found" }`

## Tasks / Subtasks

- [x] **Task 1: Adicionar action `update` ao ProfilesController** (AC: #1, #2, #3, #4, #5, #6)
  - [x] Adicionar `update` action em `app/controllers/api/v1/profiles_controller.rb`
  - [x] Buscar perfil por `params[:id]` — `rescue_from ActiveRecord::RecordNotFound` já trata 404
  - [x] Verificar se `profile.user_id == current_user.id` → HTTP 403 via helper `forbidden` se não for o dono
  - [x] `profile.update(profile_params)` — se salvo com sucesso → HTTP 200 com `ProfileSerializer`
  - [x] Se inválido → HTTP 422 com `{ error: profile.errors.full_messages.first, code: "unprocessable_entity" }`
  - [x] **NÃO** permitir alterar `profile_type` via update — remover do `profile_params` de update
  - [x] Usar os mesmos `profile_params` já existentes (exceto `profile_type`)

- [x] **Task 2: Expandir rota de profiles** (AC: #1)
  - [x] Em `config/routes.rb`, alterar `only: [ :create ]` para `only: [ :create, :update ]`

- [x] **Task 3: Escrever testes** (AC: #1–#6)
  - [x] Em `test/controllers/api/v1/profiles_controller_test.rb`:
    - PATCH com city alterada → 200 + GeocodingJob enfileirado
    - PATCH sem alterar city → 200 + nenhum job enfileirado
    - PATCH com JWT de outro usuário → 403
    - PATCH sem JWT → 401
    - PATCH com name vazio → 422
    - PATCH com :id inexistente → 404

## Dev Notes

### O que já existe (criado na Story 2.1)

- `app/models/profile.rb` — validações de `name`, `city`, `profile_type`; callback `after_save :enqueue_geocoding_if_city_changed` já funciona tanto para create quanto update
- `app/controllers/api/v1/profiles_controller.rb` — tem apenas `create`; herda de `Api::V1::ApplicationController`
- `app/serializers/profile_serializer.rb` — serializa todos os campos do perfil
- `app/jobs/geocoding_job.rb` — pronto para ser enfileirado
- `config/routes.rb` — `resources :profiles, only: [:create]`
- `ApplicationController` já tem: `authenticate_user!`, `current_profile`, `not_found`, `forbidden`, `unprocessable`
- `rescue_from ActiveRecord::RecordNotFound, with: :not_found` — trata 404 automaticamente

### Implementação do update

O `after_save :enqueue_geocoding_if_city_changed` no modelo já cuida do job quando `city` muda — **não duplicar** essa lógica no controller.

```ruby
def update
  profile = Profile.find(params[:id])   # rescue_from trata 404 automaticamente
  return forbidden unless profile.user_id == current_user.id

  if profile.update(update_params)
    render json: ProfileSerializer.new(profile).as_json, status: :ok
  else
    render json: { error: profile.errors.full_messages.first, code: "unprocessable_entity" },
           status: :unprocessable_entity
  end
end

private

def update_params
  params.permit(:name, :city, :bio, :music_genre)  # profile_type NÃO permitido
end
```

### Por que não permitir alterar `profile_type`

O `profile_type` é fixo por design (AR do sistema). Bandas não se tornam venues. Isso precisa ser bloqueado no `update_params` para evitar corrupção de dados. O modelo ainda aceita qualquer tipo válido, mas o controller não deve expor essa alteração.

### Verificação de autorização

Usar `profile.user_id == current_user.id` (comparação direta de IDs) em vez de `current_profile == profile` pois o usuário pode não ter perfil ainda quando tenta editar. O helper `forbidden` do `ApplicationController` retorna `{ error: "Acesso negado", code: "forbidden" }` com HTTP 403.

### Geocoding no update

O callback `after_save :enqueue_geocoding_if_city_changed` usa `saved_change_to_city?` que detecta automaticamente quando `city` mudou após um `update`. Não há código adicional no controller para isso. Lembrar nos testes de usar `assert_enqueued_with(job: GeocodingJob)` e `assert_no_enqueued_jobs(only: GeocodingJob)`.

### Aviso do Code Review da Story 2.1

O code review da story anterior identificou que a criação de perfil duplo (race condition) deveria ter um `rescue ActiveRecord::RecordNotUnique`. Isso é escopo da 2-1 e **não deve ser corrigido aqui** — não introduzir escopo fora da story atual.

### Project Structure Notes

- Apenas `app/controllers/api/v1/profiles_controller.rb` e `config/routes.rb` precisam ser modificados
- Testes adicionados ao arquivo existente: `test/controllers/api/v1/profiles_controller_test.rb`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.2]
- [Source: _bmad-output/planning-artifacts/architecture.md#Padrões de Autorização]
- [Source: app/controllers/api/v1/profiles_controller.rb]
- [Source: app/models/profile.rb]
- [Source: app/controllers/api/v1/application_controller.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- ✅ `ProfilesController#update` com autorização por `user_id`, 200/403/404/422
- ✅ `update_params` separado de `profile_params` — `profile_type` bloqueado de edição
- ✅ GeocodingJob enfileirado automaticamente via callback `after_save` existente no modelo
- ✅ Rota expandida para `only: [:create, :update]`
- ✅ 8 novos testes de controller — todos passando
- ✅ Suite completa: 69 testes, 0 erros, 1 falha pré-existente (CORS)

### File List

- `app/controllers/api/v1/profiles_controller.rb` (modificado — action `update` adicionada)
- `config/routes.rb` (modificado — `:update` adicionado)
- `test/controllers/api/v1/profiles_controller_test.rb` (modificado — 8 novos testes)
