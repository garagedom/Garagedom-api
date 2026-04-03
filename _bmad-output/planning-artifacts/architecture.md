---
stepsCompleted: [1, 2, 3, 4, 5, 6, 7, 8]
lastStep: 8
status: 'complete'
completedAt: '2026-04-03'
inputDocuments: ['_bmad-output/planning-artifacts/prd.md']
workflowType: 'architecture'
project_name: 'GarageDom'
user_name: 'Garagedom'
date: '2026-04-03'
---

# Architecture Decision Document

_This document builds collaboratively through step-by-step discovery. Sections are appended as we work through each architectural decision together._

## Análise de Contexto do Projeto

### Visão Geral dos Requisitos

**Requisitos Funcionais:**
38 FRs organizados em 8 domínios: Autenticação, Perfis, Mapa, Conexões, Propostas de Eventos, Comunicação, Landing Pages e Administração. Os domínios de Conexões e Propostas introduzem primitivos de negócio inéditos: conexão como unidade de negociação e proposta multi-iniciador com state machine.

**Requisitos Não-Funcionais com impacto arquitetural:**
- Chat < 500ms → WebSockets obrigatório (ActionCable)
- Mapa < 2s / pins < 1s → geolocalização indexada, caching de dados de pins
- Chat criptografado em repouso → criptografia na camada de persistência
- 99.5% uptime → deploy com health checks, isolamento de falhas do chat
- LGPD → exclusão permanente de dados pessoais (cascade delete)

**Escala & Complexidade:**
- Domínio primário: Backend API + Real-time
- Complexidade: Alta
- Componentes arquiteturais estimados: 10+ (Auth, Profiles, Map, Connections, Proposals, Chat, Notifications, Landing Pages, Admin, Storage)

### Constraints e Dependências Técnicas

- Rails API-only separado de frontend React — sem server-side rendering
- ActionCable para chat e notificações in-app em tempo real
- Leaflet no frontend — backend expõe lat/lng nos perfis via API
- Devise + Omniauth (Google + Facebook) — auth com suporte a JWT ou sessions
- 3 tipos de perfil com permissões distintas — RBAC na camada de autorização
- MVP gratuito — sem gateway de pagamento no MVP

### Cross-Cutting Concerns Identificados

1. **Autenticação & Autorização** — Devise + tipo de perfil como base para RBAC em todos os endpoints
2. **Tempo Real** — ActionCable serve tanto chat quanto notificações; canal por usuário
3. **Criptografia de mensagens** — impacta modelo de dados do chat (não texto plano no banco)
4. **Geolocalização** — lat/lng nos perfis, geocoding no cadastro
5. **Exclusão de dados (LGPD)** — cascade delete em todas as entidades associadas ao usuário
6. **State machine de Propostas** — estados: draft → sent → accepted / rejected / cancelled

## Avaliação de Template Inicial

### Domínio Tecnológico Primário

Backend API — Ruby on Rails 8.0.5 (API-only mode)

### Template: Projeto Existente — Rails 8 API

O `garagedom-api` já está inicializado como Rails 8 com `config.api_only = true`. Não é necessário criar um novo projeto.

### Setup Atual

| Componente | Gem | Notas |
|---|---|---|
| Framework | rails ~> 8.0.5 | API-only mode |
| Banco de dados | sqlite3 >= 2.1 | Desenvolvimento |
| Web server | puma >= 5.0 | |
| WebSockets | solid_cable | Rails 8 built-in, sem Redis |
| Job Queue | solid_queue | Rails 8 built-in, sem Redis |
| Cache | solid_cache | Rails 8 built-in |
| Deploy | kamal | Docker-based |
| Segurança | brakeman | dev/test |
| Lint | rubocop-rails-omakase | dev/test |
| Env vars | dotenv-rails | |

### Gems a Adicionar

- `rack-cors` — já comentado no Gemfile, ativar
- `bcrypt` — já comentado no Gemfile, ativar
- `devise` + `devise-jwt` — autenticação com JWT para API
- `omniauth-google-oauth2` + `omniauth-facebook` — OAuth social
- `pg` — PostgreSQL para produção (SQLite3 apenas em dev)

### Decisões Estabelecidas pelo Setup

- API-only: sem views, assets ou session middleware por padrão
- Solid Cable: ActionCable sem dependência de Redis no MVP
- Solid Queue: jobs assíncronos sem Redis/Sidekiq no MVP
- Kamal: deploy containerizado via Docker

## Decisões Arquiteturais

### Decisões Críticas (Bloqueiam Implementação)

- Banco de dados PostgreSQL em todos os ambientes
- Autenticação via devise-jwt (tokens JWT no header Authorization)
- Versionamento de API: `/api/v1/...`
- Criptografia de mensagens: Active Record Encryption

### Decisões Importantes (Moldam a Arquitetura)

- Geolocalização: campos `latitude`/`longitude` (decimal) + gem `geocoder`
- Formato de resposta: JSON simples (sem JSON:API spec)

### Decisões Adiadas (Pós-MVP)

- Infraestrutura de deploy: a definir (Kamal já configurado)

### Arquitetura de Dados

- **Banco:** PostgreSQL (todos os ambientes — dev, test, prod)
- **ORM:** ActiveRecord (Rails padrão)
- **Geolocalização:** campos `latitude` e `longitude` (decimal) em todos os perfis; geocoding automático via gem `geocoder` no cadastro/atualização de endereço
- **Criptografia:** Active Record Encryption (nativo Rails 7+) para o modelo `Message`

### Autenticação & Segurança

- **Autenticação:** Devise + devise-jwt — tokens JWT no header `Authorization: Bearer <token>`
- **OAuth:** Omniauth com providers Google e Facebook
- **CORS:** rack-cors configurado para aceitar requests do domínio do frontend React
- **Autorização:** controle por `profile_type` (`band`, `venue`, `producer`, `admin`) em todos os endpoints via concern ou policy

### Padrões de API & Comunicação

- **Versionamento:** namespace `/api/v1/` para todos os endpoints
- **Formato:** JSON simples — objetos planos sem envelope JSON:API
- **Tempo Real:** ActionCable via Solid Cable — canal por usuário para chat e notificações
- **Erros:** formato padronizado `{ error: "mensagem", code: "código" }`

### Frontend (fora do escopo deste repositório)

- React em repositório separado (`garagedom-web`)
- Consome a API Rails via HTTP + WebSocket (ActionCable)
- Mapa: Leaflet com pins vindos da API

### Infraestrutura & Deploy

- **Servidor web:** Puma
- **Deploy:** Kamal (Docker) — ambiente de destino a definir
- **Jobs:** Solid Queue para tarefas assíncronas (ex: geocoding)
- **Cache:** Solid Cache

## Padrões de Implementação e Regras de Consistência

### Padrões de Nomenclatura

**Banco de Dados:**
- Tabelas: `snake_case` plural — `profiles`, `connections`, `event_proposals`, `messages`
- Colunas: `snake_case` — `profile_type`, `created_at`, `latitude`
- Chaves estrangeiras: `{tabela_singular}_id` — `profile_id`, `venue_id`
- Índices: `index_{tabela}_{coluna(s)}` — `index_profiles_on_profile_type`

**Endpoints REST:**
- Recursos: plural, `snake_case` — `/api/v1/event_proposals`, `/api/v1/connections`
- Parâmetros de rota: `:id`
- Query params: `snake_case` — `?profile_type=band&city=Jundiai`

**Código Ruby:**
- Classes/Modules: `PascalCase` — `EventProposal`, `ProfilesController`
- Métodos/variáveis: `snake_case` — `create_connection`, `profile_type`
- Constantes: `SCREAMING_SNAKE_CASE` — `PROPOSAL_STATES`

### Padrões de Estrutura

**Controllers:**
```
app/controllers/api/v1/
  ├── application_controller.rb
  ├── profiles_controller.rb
  ├── connections_controller.rb
  ├── event_proposals_controller.rb
  ├── messages_controller.rb
  └── landing_pages_controller.rb
```

**Services:**
```
app/services/
  ├── connections/create_service.rb
  ├── event_proposals/create_service.rb
  └── geocoding/update_coordinates_service.rb
```

**Channels:**
```
app/channels/
  ├── application_cable/connection.rb
  ├── chat_channel.rb
  └── notifications_channel.rb
```

### Padrões de Formato

**Resposta de sucesso:** objeto plano — `{ "id": 1, "name": "Banda X", "profile_type": "band" }`

**Resposta de erro:** `{ "error": "mensagem legível", "code": "snake_case_code" }`

**Códigos de erro padronizados:** `not_found`, `unauthorized`, `forbidden`, `unprocessable_entity`, `internal_server_error`

**Datas:** ISO 8601 — `"2026-04-03T15:30:00Z"`

**JSON fields:** `snake_case` em toda a API

### Padrões de Autorização

- Verificação de `profile_type` via `before_action` nos controllers
- Helper `current_profile` disponível em todos os controllers
- HTTP 403 explícito quando tipo de perfil não tem permissão

### Padrões de ActionCable

- `ChatChannel` — subscrito por `conversation_id`
- `NotificationsChannel` — subscrito por `profile_id`
- Eventos em `snake_case` — `new_message`, `proposal_accepted`, `proposal_rejected`

### Padrões de Processo

- Tratamento de erros centralizado via `rescue_from` no `Api::V1::ApplicationController`
- State machine de propostas via gem `aasm` — estados: `draft → sent → accepted / rejected / cancelled`
- Geocoding executado via Solid Queue (job assíncrono) após criação/atualização de perfil

### Regras Obrigatórias para Todos os Agentes

- Todo controller herda de `Api::V1::ApplicationController`
- Toda rota começa com `/api/v1/`
- Toda resposta de erro usa o formato `{ error:, code: }`
- Mensagens de chat NUNCA em texto plano — sempre via Active Record Encryption
- Usar `current_profile` (não `current_user`) para o perfil autenticado

## Estrutura do Projeto & Boundaries

### Árvore de Diretórios Completa

```
garagedom-api/
├── Gemfile
├── Gemfile.lock
├── Rakefile
├── config.ru
├── .env.example
├── .gitignore
├── .rubocop.yml
├── .ruby-version
├── Dockerfile
├── .dockerignore
├── .kamal/
│   └── deploy.yml
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│   ├── channels/
│   │   ├── application_cable/
│   │   │   ├── channel.rb
│   │   │   └── connection.rb          # autenticação JWT via token no query param
│   │   ├── chat_channel.rb            # subscrito por conversation_id
│   │   └── notifications_channel.rb   # subscrito por profile_id
│   │
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   └── api/
│   │       └── v1/
│   │           ├── application_controller.rb     # rescue_from, current_profile, authorize!
│   │           ├── registrations_controller.rb   # FR01, FR02 — POST /api/v1/auth/register
│   │           ├── sessions_controller.rb        # FR03 — POST /api/v1/auth/login + logout
│   │           ├── passwords_controller.rb       # FR04 — POST /api/v1/auth/password
│   │           ├── omniauth_callbacks_controller.rb # FR02 — OAuth Google/Facebook
│   │           ├── profiles_controller.rb        # FR07–FR10
│   │           ├── map_controller.rb             # FR11–FR14 — GET /api/v1/map/pins
│   │           ├── connections_controller.rb     # FR15–FR18
│   │           ├── event_proposals_controller.rb # FR19–FR24
│   │           ├── conversations_controller.rb   # FR25, FR27
│   │           ├── messages_controller.rb        # FR26, FR30
│   │           ├── notifications_controller.rb   # FR28, FR29
│   │           ├── landing_pages_controller.rb   # FR31–FR33
│   │           └── admin/
│   │               ├── base_controller.rb        # before_action: require_admin
│   │               ├── dashboard_controller.rb   # FR35
│   │               ├── profiles_controller.rb    # FR36, FR38
│   │               └── reports_controller.rb     # FR37
│   │
│   ├── models/
│   │   ├── application_record.rb
│   │   ├── user.rb                    # Devise — has_one :profile
│   │   ├── profile.rb                 # profile_type: band/venue/producer; lat/lng; belongs_to :user
│   │   ├── connection.rb              # aasm: pending → accepted / rejected / dissolved
│   │   ├── event_proposal.rb          # aasm: draft → sent → accepted / rejected / cancelled
│   │   ├── event_proposal_participant.rb  # join: proposal ↔ profile (band slots)
│   │   ├── conversation.rb            # has_many :participants, :messages
│   │   ├── conversation_participant.rb
│   │   ├── message.rb                 # encrypts :body (Active Record Encryption)
│   │   ├── notification.rb            # polymorphic: notifiable
│   │   ├── landing_page.rb            # belongs_to :profile; has_many :blocks
│   │   ├── landing_page_block.rb      # block_type: text/image/link; position
│   │   └── report.rb                  # reportable: polymorphic (message, profile)
│   │
│   ├── services/
│   │   ├── connections/
│   │   │   ├── create_service.rb      # cria Connection + notifica ambas as partes
│   │   │   └── respond_service.rb     # accept/reject + notificação
│   │   ├── event_proposals/
│   │   │   ├── create_service.rb      # valida iniciador + participantes + envia
│   │   │   └── respond_service.rb     # accept/reject + notificações em cascata
│   │   ├── messaging/
│   │   │   └── send_message_service.rb # persiste + broadcast via ChatChannel
│   │   ├── notifications/
│   │   │   └── broadcast_service.rb   # broadcast via NotificationsChannel + persiste
│   │   └── geocoding/
│   │       └── update_coordinates_service.rb  # geocoder → lat/lng (executado via job)
│   │
│   ├── jobs/
│   │   └── geocoding_job.rb           # Solid Queue — enfileirado no after_save do Profile
│   │
│   ├── policies/                      # autorização por profile_type (sem gem externa)
│   │   ├── application_policy.rb
│   │   ├── connection_policy.rb
│   │   ├── event_proposal_policy.rb
│   │   └── admin_policy.rb
│   │
│   └── serializers/                   # objetos planos, JSON manual
│       ├── profile_serializer.rb
│       ├── connection_serializer.rb
│       ├── event_proposal_serializer.rb
│       ├── message_serializer.rb
│       └── map_pin_serializer.rb      # versão enxuta de perfil para pins do mapa
│
├── config/
│   ├── application.rb
│   ├── routes.rb                      # namespace :api, :v1 + devise routes + admin namespace
│   ├── database.yml                   # SQLite3 dev/test; PostgreSQL prod
│   ├── cable.yml                      # Solid Cable
│   ├── queue.yml                      # Solid Queue
│   ├── cache.yml                      # Solid Cache
│   ├── credentials.yml.enc
│   ├── master.key
│   ├── initializers/
│   │   ├── cors.rb                    # rack-cors — origens permitidas
│   │   ├── devise.rb
│   │   └── encryption.rb             # Active Record Encryption keys
│   └── environments/
│       ├── development.rb
│       ├── test.rb
│       └── production.rb
│
├── db/
│   ├── schema.rb
│   └── migrate/
│       ├── YYYYMMDD_create_users.rb
│       ├── YYYYMMDD_create_profiles.rb         # profile_type, lat, lng, map_visible
│       ├── YYYYMMDD_create_connections.rb
│       ├── YYYYMMDD_create_event_proposals.rb
│       ├── YYYYMMDD_create_event_proposal_participants.rb
│       ├── YYYYMMDD_create_conversations.rb
│       ├── YYYYMMDD_create_conversation_participants.rb
│       ├── YYYYMMDD_create_messages.rb         # body: encrypted
│       ├── YYYYMMDD_create_notifications.rb
│       ├── YYYYMMDD_create_landing_pages.rb
│       ├── YYYYMMDD_create_landing_page_blocks.rb
│       └── YYYYMMDD_create_reports.rb
│
├── test/
│   ├── test_helper.rb
│   ├── factories/                     # FactoryBot
│   │   ├── users.rb
│   │   ├── profiles.rb
│   │   ├── connections.rb
│   │   ├── event_proposals.rb
│   │   ├── conversations.rb
│   │   ├── messages.rb
│   │   └── landing_pages.rb
│   ├── models/
│   │   ├── user_test.rb
│   │   ├── profile_test.rb
│   │   ├── connection_test.rb
│   │   ├── event_proposal_test.rb
│   │   └── message_test.rb
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   │           ├── profiles_controller_test.rb
│   │           ├── connections_controller_test.rb
│   │           ├── event_proposals_controller_test.rb
│   │           └── map_controller_test.rb
│   ├── services/
│   │   ├── connections/create_service_test.rb
│   │   └── event_proposals/create_service_test.rb
│   └── channels/
│       ├── chat_channel_test.rb
│       └── notifications_channel_test.rb
│
└── lib/
    └── tasks/
        └── admin.rake                 # tarefas rake para manutenção/seed admin
```

### Boundaries Arquiteturais

**API Boundaries:**
- Todos os endpoints autenticados sob `/api/v1/` — JWT obrigatório via header `Authorization: Bearer <token>`
- Endpoints públicos: `GET /api/v1/map/pins`, `GET /landing/:slug`, `POST /api/v1/auth/register`, `POST /api/v1/auth/login`
- Namespace admin `/api/v1/admin/` — verificação adicional `profile_type == 'admin'`
- WebSocket handshake em `/cable` — autenticado via JWT no query param `token=`

**Component Boundaries:**
- Controllers delegam lógica de negócio para Services — sem lógica de domínio inline
- Models respondem por validações, associações e state machines (AASM)
- Services orquestram: persistência + broadcast + notificação (nunca misturar concerns)
- Policies respondem apenas à pergunta: "este `profile_type` pode executar esta ação?"

**Service Boundaries:**
- `GeocodingJob` → único caminho para atualizar `lat/lng` — nunca direto no controller
- `SendMessageService` → único caminho para persistir mensagem + broadcast — nunca direto no channel
- `BroadcastService` → único caminho para criar `Notification` + broadcast pelo `NotificationsChannel`

**Data Boundaries:**
- `Message#body` → sempre criptografado via Active Record Encryption — nunca lido como string plana fora do modelo
- `Profile#latitude`, `Profile#longitude` → escritos apenas via `GeocodingJob`, lidos diretamente na query do mapa
- `Profile#map_visible` → flag de LGPD — `MapController` filtra `where(map_visible: true)` sempre

### Mapeamento Domínio → Estrutura

| Domínio | Models | Controllers | Services | Channels |
|---|---|---|---|---|
| Auth | `User` | `registrations`, `sessions`, `passwords`, `omniauth_callbacks` | — | — |
| Perfis | `Profile` | `profiles` | `geocoding/update_coordinates_service` | — |
| Mapa | `Profile` (pins) | `map` | — | — |
| Conexões | `Connection` | `connections` | `connections/create_service`, `connections/respond_service` | — |
| Propostas | `EventProposal`, `EventProposalParticipant` | `event_proposals` | `event_proposals/create_service`, `event_proposals/respond_service` | — |
| Chat | `Conversation`, `ConversationParticipant`, `Message` | `conversations`, `messages` | `messaging/send_message_service` | `ChatChannel` |
| Notificações | `Notification` | `notifications` | `notifications/broadcast_service` | `NotificationsChannel` |
| Landing Pages | `LandingPage`, `LandingPageBlock` | `landing_pages` | — | — |
| Admin | — | `admin/dashboard`, `admin/profiles`, `admin/reports` | — | — |
| Reports | `Report` | (via `admin/reports`) | — | — |

### Pontos de Integração

**Interno (fluxo de dados):**
- `Profile after_save` → enfileira `GeocodingJob` → `UpdateCoordinatesService` → atualiza `lat/lng`
- `Connection` aceita → `BroadcastService` → `NotificationsChannel` das partes
- `EventProposal` transição de estado → `BroadcastService` → `NotificationsChannel` de todos os participantes
- `SendMessageService` → `Message.create!` → `ChatChannel.broadcast_to(conversation)`

**Externo:**
- OAuth Google/Facebook → `omniauth_callbacks_controller` → cria/encontra `User` + JWT
- Geocoder gem → API de geocoding externa (Google Maps / Nominatim) — chamado apenas via `UpdateCoordinatesService`
- Frontend React (`garagedom-web`) → consome API via HTTP + WebSocket ActionCable

## Validação da Arquitetura

### Resultado: APROVADA PARA IMPLEMENTAÇÃO

### Coerência ✅

Todas as decisões tecnológicas são compatíveis entre si. Rails 8 + PostgreSQL + devise-jwt + Solid Cable + Solid Queue + AASM + Active Record Encryption formam um stack sem conflitos. Padrões de nomenclatura e comunicação são consistentes em todos os domínios.

### Cobertura de Requisitos ✅

Todos os 38 FRs têm suporte arquitetural mapeado. NFRs de performance, segurança e LGPD estão cobertos pelas decisões de stack (ActionCable, Active Record Encryption, cascade delete, map_visible).

### Gaps Identificados e Resoluções

**[G1] Cascade Delete (LGPD — FR05)**
`User` model deve declarar `has_one :profile, dependent: :destroy` e a cadeia completa de `dependent: :destroy` em `Profile` para todas as entidades filhas. Responsabilidade: migration de FK + declaração no model.

**[G2] Slug na LandingPage (FR33–FR34)**
`LandingPage` deve ter coluna `slug: string, null: false, unique: true`. Rota pública: `GET /landing/:slug` — fora do namespace `/api/v1/`, sem autenticação.

**[G3] Índices obrigatórios para performance**
Migrations devem incluir:
- `add_index :profiles, [:latitude, :longitude]`
- `add_index :profiles, :map_visible`
- `add_index :profiles, :profile_type`
- `add_index :messages, :conversation_id`
- `add_index :connections, :initiator_id`
- `add_index :connections, :recipient_id`

**[G4] Endpoint de exclusão de conta (FR05)**
`DELETE /api/v1/account` — action `destroy` no `registrations_controller` (herda de `Devise::RegistrationsController`) que executa `current_user.destroy` (cascade automático via dependências).

**[G5] ActionCable — autenticação JWT**
`application_cable/connection.rb` deve extrair e validar o JWT do query param `token=`:
```ruby
identified_by :current_profile
def connect
  token = request.params[:token]
  payload = Warden::JWTAuth::TokenDecoder.new.call(token)
  self.current_profile = Profile.find(payload['sub'])
rescue
  reject_unauthorized_connection
end
```

### Checklist de Completude

**✅ Análise de Requisitos**
- [x] Contexto do projeto analisado
- [x] Escala e complexidade avaliadas
- [x] Constraints técnicas identificadas
- [x] Cross-cutting concerns mapeados

**✅ Decisões Arquiteturais**
- [x] Decisões críticas documentadas
- [x] Stack tecnológico especificado
- [x] Padrões de integração definidos
- [x] Performance e segurança endereçados

**✅ Padrões de Implementação**
- [x] Convenções de nomenclatura estabelecidas
- [x] Padrões de estrutura definidos
- [x] Padrões de comunicação especificados
- [x] Tratamento de erros documentado

**✅ Estrutura do Projeto**
- [x] Árvore completa de diretórios definida
- [x] Boundaries de componentes estabelecidos
- [x] Pontos de integração mapeados
- [x] Requisitos mapeados à estrutura

### Avaliação de Prontidão

**Status Geral:** PRONTO PARA IMPLEMENTAÇÃO
**Nível de Confiança:** Alto

**Pontos Fortes:**
- Stack coeso e nativo Rails 8 — sem dependências externas no MVP (sem Redis)
- State machines explícitas via AASM evitam lógica de estado dispersa
- Active Record Encryption nativo elimina complexidade de criptografia custom
- Boundaries claros entre controllers / services / models / channels

**Prioridade de Implementação:**
1. Setup inicial: PostgreSQL, devise-jwt, rack-cors, bcrypt, aasm
2. Models + migrations (com índices e cascade delete)
3. Auth controllers (registro, login, OAuth, exclusão de conta)
4. Profiles + geocoding + map endpoint
5. Connections + state machine
6. EventProposals + multi-iniciador
7. Chat + ActionCable (ChatChannel + NotificationsChannel)
8. Landing Pages
9. Admin namespace
