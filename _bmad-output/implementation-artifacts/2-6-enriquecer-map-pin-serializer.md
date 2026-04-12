# Story 2.6: Enriquecer MapPinSerializer com logo_url, music_genre e city

Status: ready-for-dev

## Story

Como frontend do Epic 4 (Mapa e Descoberta),
quero que cada pin retornado por `GET /api/v1/map/pins` inclua `logo_url`, `music_genre` e `city`,
para que o mapa exiba cards ricos com informações visuais sem chamadas adicionais por pin.

## Acceptance Criteria

1. **[CAMPOS_ENRIQUECIDOS]** `GET /api/v1/map/pins` com JWT válido
   - Cada pin agora retorna: `id`, `name`, `profile_type`, `latitude`, `longitude`, `city`, `music_genre`, `logo_url`
   - `logo_url`: URL pública do Active Storage blob, ou `null` se nenhum logo anexado
   - `music_genre`: string ou `null` para venues/producers sem gênero cadastrado
   - `city`: string ou `null` se não geocodificado ainda

2. **[LOGO_URL_VALIDA]** Perfil com logo anexado
   - `logo_url` retorna URL navegável (rails_blob_url ou ActiveStorage representação pública)
   - A URL pode ser aberta por clientes externos (sem exigir cookie de sessão)

3. **[LOGO_URL_NULA]** Perfil sem logo
   - `logo_url` retorna `null` — não retorna string vazia nem campo ausente

4. **[RETROCOMPATIBILIDADE]** Campos anteriores preservados
   - `id`, `name`, `profile_type`, `latitude`, `longitude` continuam presentes e sem alteração

5. **[SEM_REGRESSAO]** Suite de testes anterior continua passando
   - Todos os 8 testes de `map_controller_test.rb` passam sem modificação de assertions existentes

## Tasks / Subtasks

- [ ] **Task 1: Atualizar MapPinSerializer** (AC: #1, #2, #3, #4)
  - [ ] Adicionar `city`, `music_genre` ao hash retornado por `as_json`
  - [ ] Gerar `logo_url` via `Rails.application.routes.url_helpers.rails_blob_url` se logo anexado, `nil` caso contrário
  - [ ] Injetar `include Rails.application.routes.url_helpers` ou receber URL como parâmetro (ver Dev Notes)

- [ ] **Task 2: Atualizar MapController para eager load de logo** (AC: #2)
  - [ ] Adicionar `.with_attached_logo` ao escopo da query para evitar N+1
  - [ ] Exemplo: `Profile.where(map_visible: true).where.not(...).with_attached_logo`

- [ ] **Task 3: Atualizar testes** (AC: #4, #5)
  - [ ] Adicionar assertions para `city`, `music_genre`, `logo_url` nos testes existentes de `map_controller_test.rb`
  - [ ] Criar perfil de teste com logo anexado para cobrir AC #2
  - [ ] Garantir que perfil sem logo retorna `logo_url: null`

## Dev Notes

### O que já existe

- `app/serializers/map_pin_serializer.rb` — retorna apenas 5 campos (id, name, profile_type, latitude, longitude)
- `app/controllers/api/v1/map_controller.rb` — query básica sem `with_attached_logo`
- `app/models/profile.rb` — tem `has_one_attached :logo`, coluna `music_genre`, coluna `city`
- Gem `active_storage` já configurada (usado em `ProfileSerializer`)

### MapPinSerializer — versão enriquecida

```ruby
class MapPinSerializer
  include Rails.application.routes.url_helpers

  def initialize(profile)
    @profile = profile
  end

  def as_json
    {
      id: @profile.id,
      name: @profile.name,
      profile_type: @profile.profile_type,
      latitude: @profile.latitude,
      longitude: @profile.longitude,
      city: @profile.city,
      music_genre: @profile.music_genre,
      logo_url: logo_url_for(@profile)
    }
  end

  private

  def logo_url_for(profile)
    return nil unless profile.logo.attached?
    rails_blob_url(profile.logo, only_path: false)
  end
end
```

**Atenção**: `rails_blob_url` exige que `default_url_options[:host]` esteja configurado.
Em produção o Rails já tem `config.action_mailer.default_url_options` — verificar se `routes.default_url_options` também está definido.
Se não estiver, usar `rails_blob_path` (caminho relativo) que não precisa de host.

### MapController — N+1 prevention

```ruby
def pins
  profiles = Profile.where(map_visible: true)
                    .where.not(latitude: nil, longitude: nil)
                    .with_attached_logo  # <-- adicionar esta linha
  profiles = profiles.where(profile_type: params[:profile_type]) if params[:profile_type].present?
  profiles = profiles.where("LOWER(city) = LOWER(?)", params[:city]) if params[:city].present?
  render json: profiles.map { |p| MapPinSerializer.new(p).as_json }, status: :ok
end
```

### Teste com logo anexado

```ruby
test "pin includes logo_url when logo is attached" do
  file = fixture_file_upload("logo.png", "image/png")
  @band.logo.attach(file)
  get api_v1_map_pins_path, headers: auth_headers(@token)
  pins = JSON.parse(response.body)
  band_pin = pins.find { |p| p["id"] == @band.id }
  assert_not_nil band_pin["logo_url"]
  assert_match /logo/, band_pin["logo_url"]
end

test "pin has logo_url null when no logo" do
  get api_v1_map_pins_path, headers: auth_headers(@token)
  pins = JSON.parse(response.body)
  band_pin = pins.find { |p| p["id"] == @band.id }
  assert_nil band_pin["logo_url"]
end
```

Colocar fixture `logo.png` em `test/fixtures/files/logo.png` (qualquer PNG pequeno serve).

### References

- [Source: app/serializers/map_pin_serializer.rb]
- [Source: app/controllers/api/v1/map_controller.rb]
- [Source: app/models/profile.rb]
- [Blocks: frontend stories 4-1, 4-2, 4-3 — cards de pin no mapa precisam de logo_url, music_genre, city]
