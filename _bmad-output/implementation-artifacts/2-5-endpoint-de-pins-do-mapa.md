# Story 2.5: Endpoint de Pins do Mapa

Status: review

## Story

Como qualquer usuário autenticado,
quero ver pins de bandas, venues e produtores no mapa e filtrá-los por tipo,
para que eu possa descobrir músicos e espaços geograficamente.

## Acceptance Criteria

1. **[PINS_BASICO]** `GET /api/v1/map/pins` com JWT válido
   - HTTP 200 com array de perfis onde `map_visible: true`
   - Cada item contém apenas: `id`, `name`, `profile_type`, `latitude`, `longitude`
   - Perfis com `latitude` ou `longitude` nulos (geocoding pendente) excluídos

2. **[FILTRO_TIPO]** `GET /api/v1/map/pins?profile_type=band`
   - Retorna apenas perfis com `profile_type: "band"`
   - Mesmo filtro funciona para `venue` e `producer`

3. **[FILTRO_CIDADE]** `GET /api/v1/map/pins?city=Jundiai`
   - Retorna apenas perfis da cidade correspondente (case-insensitive)

4. **[SEM_AUTENTICACAO]** Sem JWT válido
   - HTTP 401

5. **[MAPA_VAZIO]** Nenhum perfil visível geocodificado
   - HTTP 200 com array vazio `[]`

## Tasks / Subtasks

- [x] **Task 1: Criar MapPinSerializer** (AC: #1)
  - [x] Criar `app/serializers/map_pin_serializer.rb`
  - [x] Retorna hash com apenas: `id`, `name`, `profile_type`, `latitude`, `longitude`
  - [x] **NÃO** incluir `bio`, `city`, `map_visible`, `user_id` — versão enxuta para o mapa

- [x] **Task 2: Criar MapController** (AC: #1, #2, #3, #4, #5)
  - [x] Criar `app/controllers/api/v1/map_controller.rb`
  - [x] Herdar de `Api::V1::ApplicationController`
  - [x] Action `pins` com escopo base + filtros opcionais de `profile_type` e `city`

- [x] **Task 3: Adicionar rota** (AC: #1)
  - [x] `get "map/pins", to: "map#pins"` adicionado ao namespace api/v1

- [x] **Task 4: Escrever testes** (AC: #1–#5)
  - [x] `test/controllers/api/v1/map_controller_test.rb` com 8 testes cobrindo todos os ACs

## Dev Notes

### O que já existe

- `app/models/profile.rb` — `map_visible`, `latitude`, `longitude`, `profile_type`, `city`
- Índices criados na Story 2.1: `profiles(map_visible)`, `profiles(latitude, longitude)`, `profiles(profile_type)`
- `Api::V1::ApplicationController` com `authenticate_user!`, helpers de erro
- `app/serializers/profile_serializer.rb` já existe — `MapPinSerializer` é uma versão **separada e mais enxuta**

### MapPinSerializer — versão enxuta

```ruby
class MapPinSerializer
  def initialize(profile)
    @profile = profile
  end

  def as_json
    {
      id: @profile.id,
      name: @profile.name,
      profile_type: @profile.profile_type,
      latitude: @profile.latitude,
      longitude: @profile.longitude
    }
  end
end
```

Não reutilizar `ProfileSerializer` — o mapa precisa de payload mínimo por performance (NFR02: pins < 1s).

### MapController — query segura

```ruby
def pins
  profiles = Profile.where(map_visible: true).where.not(latitude: nil, longitude: nil)
  profiles = profiles.where(profile_type: params[:profile_type]) if params[:profile_type].present?
  profiles = profiles.where("LOWER(city) = LOWER(?)", params[:city]) if params[:city].present?
  render json: profiles.map { |p| MapPinSerializer.new(p).as_json }, status: :ok
end
```

- Usar `LOWER(city) = LOWER(?)` para busca case-insensitive sem expor a SQL injection
- **NÃO** usar `city: params[:city]` direto (case-sensitive) — spec diz "cidade correspondente"
- O filtro `profile_type` é seguro pois o modelo valida `VALID_TYPES`; mesmo assim o `where` parametrizado protege

### Rota fora do `resources :profiles`

O MapController é um controller separado. A rota é:
```ruby
get "map/pins", to: "map#pins"
```
Não é nested sob profiles. Colocar antes ou depois de `resources :profiles` dentro do namespace.

### Testes — setup com perfis variados

```ruby
setup do
  @user = User.create!(...)
  @token = jwt_token_for(@user)
  # Criar perfis com coordenadas para aparecer no mapa
  @band = FactoryBot.create(:profile, profile_type: "band", map_visible: true,
                             latitude: -23.18, longitude: -46.89, city: "Jundiaí")
  @venue = FactoryBot.create(:profile, :venue, map_visible: true,
                              latitude: -22.90, longitude: -43.17, city: "Rio de Janeiro")
  @hidden = FactoryBot.create(:profile, :producer, map_visible: false,
                               latitude: -23.18, longitude: -46.89)
  @no_coords = FactoryBot.create(:profile, profile_type: "band", map_visible: true,
                                  latitude: nil, longitude: nil)
end
```

Cada perfil precisa de um `user` diferente (índice único `user_id` na tabela profiles).

### Project Structure Notes

- Novo arquivo: `app/controllers/api/v1/map_controller.rb`
- Novo arquivo: `app/serializers/map_pin_serializer.rb`
- Modificar: `config/routes.rb`
- Novo teste: `test/controllers/api/v1/map_controller_test.rb`

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.5]
- [Source: _bmad-output/planning-artifacts/architecture.md#Mapeamento Domínio → Estrutura]
- [Source: _bmad-output/planning-artifacts/architecture.md#Gaps Identificados — G3]
- [Source: app/serializers/profile_serializer.rb]
- [Source: app/models/profile.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

- Testes de city com `params:` e `as: :json` em GET retornavam 404 — Rails encoda params como body JSON. Corrigido usando query string direta na URL com cidades ASCII.

### Completion Notes List

- ✅ `MapPinSerializer` — payload enxuto (5 campos) separado do `ProfileSerializer`
- ✅ `MapController#pins` com escopo base + filtros opcionais encadeados
- ✅ Filtro city usa `LOWER(city) = LOWER(?)` — case-insensitive e protegido contra SQL injection
- ✅ Rota `GET /api/v1/map/pins` adicionada
- ✅ 8 testes: pins básicos, exclusão de hidden/sem-coords, filtro por tipo, filtro por cidade, array vazio, 401
- ✅ Suite completa: 83 testes, 0 erros, 1 falha pré-existente (CORS)

### File List

- `app/serializers/map_pin_serializer.rb` (novo)
- `app/controllers/api/v1/map_controller.rb` (novo)
- `config/routes.rb` (modificado — `get "map/pins"`)
- `test/controllers/api/v1/map_controller_test.rb` (novo)
