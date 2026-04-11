# Story 2.1: Criação de Perfil com Geocoding

Status: review

## Story

Como usuário autenticado,
quero criar meu perfil com tipo fixo (banda, venue ou produtor) e cidade,
para que eu apareça no mapa e seja descoberto por outros usuários.

## Acceptance Criteria

1. **[CRIACAO_SUCESSO]** `POST /api/v1/profiles` com JWT válido, `profile_type` (band/venue/producer), `name`, `city`, e campos opcionais (`bio`, `music_genre`)
   - Perfil criado com `map_visible: true` por padrão
   - `GeocodingJob` enfileirado via Solid Queue para converter `city` em `latitude`/`longitude`
   - HTTP 201 com dados do perfil criado

2. **[TIPO_INVALIDO]** `profile_type` ausente ou inválido (qualquer valor fora de band/venue/producer)
   - HTTP 422 com `{ error: "Tipo de perfil inválido", code: "invalid_profile_type" }`

3. **[PERFIL_JA_EXISTE]** Usuário já possui perfil cadastrado
   - HTTP 422 com `{ error: "Usuário já possui perfil", code: "profile_already_exists" }`

4. **[SEM_AUTENTICACAO]** Requisição sem JWT válido
   - HTTP 401 (pelo `before_action :authenticate_user!` já existente)

5. **[CAMPOS_OBRIGATORIOS]** `name` ou `city` ausentes
   - HTTP 422 com detalhes do erro de validação

## Tasks / Subtasks

- [x] **Task 1: Criar migration de profiles** (AC: #1, #2, #3, #5)
  - [x] Gerar migration: `rails generate migration CreateProfiles`
  - [x] Campos obrigatórios: `profile_type:string`, `name:string`, `city:string`, `map_visible:boolean`
  - [x] Campos opcionais: `bio:text`, `music_genre:string`
  - [x] Geolocalização: `latitude:decimal{precision:10,scale:6}`, `longitude:decimal{precision:10,scale:6}` (nullable — preenchidos pelo GeocodingJob)
  - [x] FK: `user:references` (NOT NULL, unique — um perfil por usuário)
  - [x] Defaults: `map_visible: true`, `latitude: null`, `longitude: null`
  - [x] Índices obrigatórios (AR12):
    - `add_index :profiles, [:latitude, :longitude]`
    - `add_index :profiles, :map_visible`
    - `add_index :profiles, :profile_type`
    - `add_index :profiles, :user_id, unique: true` (um perfil por usuário)
  - [x] Rodar `rails db:migrate`

- [x] **Task 2: Criar modelo Profile** (AC: #1, #2, #3, #5)
  - [x] Criar `app/models/profile.rb`
  - [x] `belongs_to :user`
  - [x] `validates :profile_type, inclusion: { in: %w[band venue producer], message: :invalid_profile_type }, presence: true`
  - [x] `validates :name, presence: true`
  - [x] `validates :city, presence: true`
  - [x] `after_save :enqueue_geocoding_if_city_changed` — enfileira `GeocodingJob` apenas quando `city` foi alterado (`saved_change_to_city?`)
  - [x] **NÃO** incluir `enum` nativo do Rails para profile_type — usar apenas validação `inclusion` (compatibilidade futura)

- [x] **Task 3: Atualizar modelo User** (AC: #3)
  - [x] Adicionar `has_one :profile, dependent: :destroy` ao `app/models/user.rb`
  - [x] Garantir que a validação de unicidade via índice DB cobre o caso de profile duplicado

- [x] **Task 4: Criar GeocodingJob** (AC: #1)
  - [x] Criar `app/jobs/geocoding_job.rb` usando `ApplicationJob` (Solid Queue é o adapter padrão no Rails 8)
  - [x] Recebe `profile_id` como argumento
  - [x] Busca o perfil; se não existir, retorna sem erro (perfil pode ter sido deletado)
  - [x] Chama `Geocoding::UpdateCoordinatesService.new(profile).call`
  - [x] `queue_as :default`

- [x] **Task 5: Criar GeocodingService** (AC: #1)
  - [x] Criar `app/services/geocoding/update_coordinates_service.rb`
  - [x] Inicializa com um `profile`
  - [x] Usa a gem `geocoder`: `results = Geocoder.search(profile.city)`
  - [x] Se resultados encontrados: `profile.update_columns(latitude: results.first.latitude, longitude: results.first.longitude)`
  - [x] Usar `update_columns` (não `update`) para evitar disparar callbacks e novo job
  - [x] Se geocoder não encontrar resultado: logar warning, não levantar exceção

- [x] **Task 6: Criar ProfileSerializer** (AC: #1)
  - [x] Criar `app/serializers/profile_serializer.rb`
  - [x] Método `as_json` retornando hash com: `id`, `profile_type`, `name`, `bio`, `city`, `music_genre`, `map_visible`, `latitude`, `longitude`, `user_id`, `created_at`, `updated_at`
  - [x] **Não usar** gems de serialização (jbuilder, fast_jsonapi) — JSON manual conforme padrão do projeto

- [x] **Task 7: Criar ProfilesController** (AC: #1, #2, #3, #4, #5)
  - [x] Criar `app/controllers/api/v1/profiles_controller.rb`
  - [x] Herdar de `Api::V1::ApplicationController` (já tem `authenticate_user!` e helpers)
  - [x] Action `create`:
    - Verificar se `current_profile` já existe → 422 com `{ error: "Usuário já possui perfil", code: "profile_already_exists" }`
    - `profile = current_user.build_profile(profile_params)`
    - Se `profile.save` → HTTP 201 com `ProfileSerializer.new(profile).as_json`
    - Se inválido por profile_type → 422 com `{ error: "Tipo de perfil inválido", code: "invalid_profile_type" }`
    - Se inválido por outros campos → 422 com erros de validação
  - [x] `profile_params`: permit `:profile_type, :name, :city, :bio, :music_genre`

- [x] **Task 8: Adicionar rota** (AC: #1)
  - [x] Em `config/routes.rb`, dentro do `namespace :api / :v1`:
    ```ruby
    resources :profiles, only: [:create]
    ```
  - [x] Esta rota será expandida com `show`, `update` nas stories 2.2, 2.3 e 2.4

- [x] **Task 9: Escrever testes** (AC: #1–#5)
  - [x] Criar `test/factories/profiles.rb` com FactoryBot
  - [x] Criar `test/models/profile_test.rb`:
    - Validação de profile_type inválido
    - Validação de name ausente
    - Validação de city ausente
    - Unicidade de perfil por usuário
    - Callback enfileira GeocodingJob quando city salvo
  - [x] Criar `test/controllers/api/v1/profiles_controller_test.rb`:
    - POST com dados válidos → 201 + job enfileirado
    - POST com profile_type inválido → 422 + código correto
    - POST quando perfil já existe → 422 + código correto
    - POST sem JWT → 401
    - POST sem name/city → 422

## Dev Notes

### Estado atual do projeto

- **Schema atual:** apenas tabela `users` (com Devise: email, encrypted_password, jti, terms_accepted, blocked, provider, uid)
- **Gems disponíveis:** `geocoder` e `aasm` já no Gemfile e instaladas (story 1.1)
- **ApplicationController** (`app/controllers/api/v1/application_controller.rb`) já tem:
  - `before_action :authenticate_user!`
  - `current_profile` → `current_user&.profile`
  - Helpers: `not_found`, `forbidden`, `unprocessable(message, code)`
  - `rescue_from ActiveRecord::RecordNotFound, with: :not_found`
- **Rotas existentes:** devise (login/logout/register/password/oauth), `DELETE /api/v1/account`
- **Nenhum modelo Profile existe ainda** — esta story cria do zero

### Padrão de serialização do projeto

Sem gems de serialização — JSON manual. Olhar `app/serializers/` quando criado.  
Resposta de sucesso: objeto plano — `{ "id": 1, "name": "Banda X", "profile_type": "band", ... }`  
Resposta de erro: `{ "error": "mensagem legível", "code": "snake_case_code" }`

### Geocoding — detalhes críticos

- **Geocoder já instalado** (story 1.1, linha 28 do Gemfile)
- Por padrão usa Nominatim (OpenStreetMap) — sem chave de API necessária em dev/test
- Em teste: usar `Geocoder::Lookup::Test` para evitar chamadas externas:
  ```ruby
  # test/test_helper.rb (adicionar):
  Geocoder.configure(lookup: :test)
  Geocoder::Lookup::Test.set_default_stub(
    [{ "coordinates" => [-23.1896, -46.8956] }]
  )
  ```
- `GeocodingJob` deve ser testado com `assert_enqueued_with(job: GeocodingJob)`
- **NUNCA** chamar geocoder síncrono no controller — sempre via Job (AR09)

### Controle de quando enfileirar GeocodingJob

No `after_save` do modelo Profile, usar `saved_change_to_city?` (Rails change tracking):
```ruby
after_save :enqueue_geocoding_if_city_changed

private

def enqueue_geocoding_if_city_changed
  GeocodingJob.perform_later(id) if saved_change_to_city?
end
```
Isso garante que o job é enfileirado tanto na criação (city salvo pela primeira vez) quanto na edição (story 2.2).

### Tratamento de erros no controller

`ApplicationController` já tem `unprocessable(message, code)`. Usar para os erros customizados:
```ruby
# Perfil já existe:
return unprocessable("Usuário já possui perfil", "profile_already_exists") if current_profile.present?

# profile_type inválido (após save falhar):
if profile.errors[:profile_type].present?
  return unprocessable("Tipo de perfil inválido", "invalid_profile_type")
end
```

### Dependências das stories seguintes

Esta story cria a fundação usada pelas stories 2.2–2.5:
- **2.2 (Edição):** adiciona `update` ao ProfilesController e expandirá rotas
- **2.3 (Visibilidade):** usa `map_visible` (já criado aqui)
- **2.4 (Perfil público):** adiciona `show` ao ProfilesController
- **2.5 (Pins do mapa):** cria MapController que lê `latitude`, `longitude`, `map_visible`, `profile_type`

**NÃO implementar** lógica de edição, visibilidade ou mapa nesta story — apenas o `create`.

### Project Structure Notes

- Controller: `app/controllers/api/v1/profiles_controller.rb`
- Model: `app/models/profile.rb`
- Job: `app/jobs/geocoding_job.rb`
- Service: `app/services/geocoding/update_coordinates_service.rb`
- Serializer: `app/serializers/profile_serializer.rb`
- Migration: `db/migrate/YYYYMMDD_create_profiles.rb`
- Testes: `test/models/profile_test.rb`, `test/controllers/api/v1/profiles_controller_test.rb`, `test/factories/profiles.rb`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.1]
- [Source: _bmad-output/planning-artifacts/architecture.md#Padrões de Estrutura]
- [Source: _bmad-output/planning-artifacts/architecture.md#Boundaries Arquiteturais]
- [Source: _bmad-output/planning-artifacts/architecture.md#Gaps Identificados — G3 (índices)]
- [Source: _bmad-output/planning-artifacts/architecture.md#Service Boundaries]
- [Source: app/controllers/api/v1/application_controller.rb]
- [Source: app/models/user.rb]
- [Source: db/schema.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- PostgreSQL local não estava rodando → iniciado via `brew services start postgresql@14` e role `garagedom` criada
- Segfault na suite paralela (`pg` gem + workers) → resolvido rodando com `PARALLEL_WORKERS=1`
- Falha CORS no `application_controller_test.rb` confirmada como pré-existente (existia antes das mudanças)

### Completion Notes List

- ✅ Migration `20260411225549_create_profiles.rb` criada com todos os campos, FK única e índices obrigatórios (AR12)
- ✅ Modelo `Profile` com validações de presence/inclusion e callback `after_save` para GeocodingJob
- ✅ `User` atualizado com `has_one :profile, dependent: :destroy`
- ✅ `GeocodingJob` com guard de perfil deletado (`find_by` + return)
- ✅ `Geocoding::UpdateCoordinatesService` com `update_columns` (evita callbacks) e rescue para falhas de geocoding
- ✅ `ProfileSerializer` com JSON manual seguindo padrão do projeto
- ✅ `ProfilesController#create` com todos os fluxos de erro mapeados
- ✅ Rota `POST /api/v1/profiles` adicionada
- ✅ Geocoder configurado em modo test com stub no `test_helper.rb`
- ✅ 9 testes de modelo + 9 testes de controller — todos passando
- ✅ Suite completa: 61 testes, 0 erros, 1 falha pré-existente (CORS)

### File List

- `db/migrate/20260411225549_create_profiles.rb` (novo)
- `app/models/profile.rb` (novo)
- `app/models/user.rb` (modificado — `has_one :profile`)
- `app/jobs/geocoding_job.rb` (novo)
- `app/services/geocoding/update_coordinates_service.rb` (novo)
- `app/serializers/profile_serializer.rb` (novo)
- `app/controllers/api/v1/profiles_controller.rb` (novo)
- `config/routes.rb` (modificado — `resources :profiles, only: [:create]`)
- `test/test_helper.rb` (modificado — Geocoder stub)
- `test/factories/profiles.rb` (novo)
- `test/models/profile_test.rb` (novo)
- `test/controllers/api/v1/profiles_controller_test.rb` (novo)
