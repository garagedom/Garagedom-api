# Story 2.7: MapChannel via ActionCable para broadcast em tempo real

Status: ready-for-dev

## Story

Como usuário autenticado visualizando o mapa,
quero receber atualizações automáticas quando novos perfis se tornam visíveis ou mudam de posição,
para que o mapa reflita o estado atual da plataforma sem precisar recarregar a página.

## Acceptance Criteria

1. **[CHANNEL_SUBSCRIBE]** Cliente conectado ao canal `MapChannel`
   - Conexão aceita quando JWT válido fornecido via query string ou cookie
   - Conexão rejeitada (stream não iniciado) quando sem autenticação válida

2. **[BROADCAST_NOVO_PIN]** Perfil torna-se visível no mapa
   - Quando `map_visible` muda de `false` para `true` E perfil tem coordenadas
   - Broadcast enviado ao stream `"map"` com evento `{ type: "pin_added", pin: <MapPinSerializer> }`
   - Payload de `pin` inclui os 8 campos enriquecidos da Story 2.6: `id`, `name`, `profile_type`, `latitude`, `longitude`, `city`, `music_genre`, `logo_url`

3. **[BROADCAST_PIN_REMOVIDO]** Perfil deixa de ser visível
   - Quando `map_visible` muda de `true` para `false`
   - Broadcast: `{ type: "pin_removed", pin_id: <id> }`

4. **[BROADCAST_PIN_ATUALIZADO]** Perfil visível tem nome, logo ou music_genre alterados
   - Broadcast: `{ type: "pin_updated", pin: <MapPinSerializer> }`
   - Disparado apenas se o perfil já está visível com coordenadas

5. **[SEM_AUTENTICACAO]** Tentativa de subscribe sem JWT
   - Canal rejeita a conexão; cliente não entra em nenhum stream

## Tasks / Subtasks

- [ ] **Task 1: Criar ApplicationCable** (pré-requisito)
  - [ ] Criar `app/channels/application_cable/connection.rb` — autentica via JWT no query string
  - [ ] Criar `app/channels/application_cable/channel.rb` — base vazia padrão Rails
  - [ ] Criar `config/cable.yml` — adapter `solid_cable` (já instalado) para production, `async` para test/development

- [ ] **Task 2: Criar MapChannel** (AC: #1, #5)
  - [ ] Criar `app/channels/map_channel.rb`
  - [ ] `subscribed`: verificar `current_user` presente; se sim `stream_from "map"`, senão `reject`
  - [ ] `unsubscribed`: log/noop

- [ ] **Task 3: Broadcast no Profile model via callbacks** (AC: #2, #3, #4)
  - [ ] Criar `app/services/map_broadcast_service.rb` — encapsula lógica de broadcast
  - [ ] Adicionar `after_commit` em `Profile` para chamar o service
  - [ ] Detectar mudança em `map_visible`, `latitude`, `longitude`, `name`, `music_genre`, `logo`

- [ ] **Task 4: Escrever testes** (AC: #1–#5)
  - [ ] `test/channels/map_channel_test.rb` cobrindo subscribe autenticado, reject sem auth, broadcasts dos 3 tipos de evento

## Dev Notes

### Estrutura de arquivos a criar

```
app/channels/
  application_cable/
    connection.rb
    channel.rb
  map_channel.rb
app/services/
  map_broadcast_service.rb
config/cable.yml
```

### ApplicationCable::Connection — autenticação JWT

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      return reject_unauthorized_connection if token.blank?

      payload = JwtService.decode(token)
      user = User.find_by(id: payload["sub"])
      user || reject_unauthorized_connection
    rescue JWT::DecodeError
      reject_unauthorized_connection
    end
  end
end
```

**Nota**: `JwtService` — verificar se este módulo já existe no projeto. Se a decodificação JWT está inline no `ApplicationController`, extrair para `JwtService` ou usar o mesmo helper. Consultar `app/controllers/api/v1/application_controller.rb` para ver como o token é decodificado hoje.

### MapChannel

```ruby
class MapChannel < ApplicationCable::Channel
  def subscribed
    if current_user
      stream_from "map"
    else
      reject
    end
  end

  def unsubscribed
    # cleanup automático pelo ActionCable
  end
end
```

### MapBroadcastService

```ruby
class MapBroadcastService
  def self.broadcast_pin_added(profile)
    ActionCable.server.broadcast("map", {
      type: "pin_added",
      pin: MapPinSerializer.new(profile).as_json
    })
  end

  def self.broadcast_pin_removed(profile_id)
    ActionCable.server.broadcast("map", {
      type: "pin_removed",
      pin_id: profile_id
    })
  end

  def self.broadcast_pin_updated(profile)
    ActionCable.server.broadcast("map", {
      type: "pin_updated",
      pin: MapPinSerializer.new(profile).as_json
    })
  end
end
```

### Profile model — callbacks

```ruby
# app/models/profile.rb
after_commit :broadcast_map_changes

private

def broadcast_map_changes
  visible_with_coords = map_visible? && latitude.present? && longitude.present?

  if saved_change_to_map_visible?
    if map_visible? # ficou visível
      MapBroadcastService.broadcast_pin_added(self) if visible_with_coords
    else # ficou invisível
      MapBroadcastService.broadcast_pin_removed(id)
    end
  elsif visible_with_coords && (saved_change_to_name? || saved_change_to_music_genre? ||
                                  saved_change_to_latitude? || saved_change_to_longitude?)
    MapBroadcastService.broadcast_pin_updated(self)
  end
  # Logo é Active Storage — não tem saved_change_to_logo?
  # Para logo: considerar broadcast_pin_updated após attach/detach via hook separado ou job
end
```

**Atenção logo**: `after_commit` no model não captura mudanças de Active Storage attachments (eles salvam em tabela separada `active_storage_attachments`). Para broadcast após troca de logo, o controller `ProfilesController#update` pode chamar `MapBroadcastService.broadcast_pin_updated(profile)` diretamente após o attach.

### config/cable.yml

```yaml
development:
  adapter: async

test:
  adapter: test

production:
  adapter: solid_cable
```

**Nota**: `solid_cable` já está no Gemfile. Verificar se a migration `solid_cable` foi rodada (`db:migrate`). A gem cria tabela `solid_cable_messages`.

### Testes de channel

```ruby
# test/channels/map_channel_test.rb
require "test_helper"

class MapChannelTest < ActionCable::Channel::TestCase
  test "subscribes and streams from map when authenticated" do
    stub_connection current_user: users(:one)
    subscribe
    assert subscription.confirmed?
    assert_has_stream "map"
  end

  test "rejects subscription without user" do
    stub_connection current_user: nil
    subscribe
    assert subscription.rejected?
  end

  test "broadcast_pin_added sends correct payload" do
    stub_connection current_user: users(:one)
    subscribe
    profile = profiles(:band_visible)
    expect_broadcasts("map") do
      MapBroadcastService.broadcast_pin_added(profile)
    end
  end
end
```

### Rota WebSocket

Adicionar ao `config/routes.rb`:

```ruby
mount ActionCable.server => "/cable"
```

### References

- [Depends on: Story 2.6 — MapPinSerializer deve retornar 8 campos antes de usar aqui]
- [Source: app/models/profile.rb]
- [Source: app/serializers/map_pin_serializer.rb]
- [Blocks: frontend story 4-4 — mapa em tempo real via ActionCable]
- [Source: Gemfile — solid_cable já instalado]
