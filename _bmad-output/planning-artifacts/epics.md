---
stepsCompleted: [1, 2, 3, 4]
status: 'complete'
completedAt: '2026-04-03'
inputDocuments: ['_bmad-output/planning-artifacts/prd.md', '_bmad-output/planning-artifacts/architecture.md']
---

# GarageDom - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for GarageDom, decomposing the requirements from the PRD and Architecture into implementable stories.

## Requirements Inventory

### Functional Requirements

FR01: Visitante pode criar conta com e-mail e senha
FR02: Visitante pode criar conta via OAuth (Google ou Facebook)
FR03: Usuário pode fazer login com e-mail/senha ou OAuth
FR04: Usuário pode recuperar senha por e-mail
FR05: Usuário pode excluir conta e dados permanentemente (LGPD)
FR06: Usuário aceita termos de uso e política de privacidade no cadastro
FR07: Usuário cria perfil com tipo fixo: banda, casa de shows ou produtor
FR08: Usuário edita informações do perfil (nome, bio, gênero musical, cidade, membros, fotos)
FR09: Usuário controla visibilidade do pin no mapa (público ou oculto)
FR10: Usuário visualiza perfil público de outros usuários
FR11: Usuário visualiza mapa interativo com pins de bandas, venues e produtores por cidade
FR12: Usuário clica em pin para visualizar perfil resumido da entidade
FR13: Usuário filtra pins por tipo de entidade (banda, venue, produtor)
FR14: Usuário navega pelo mapa livremente (zoom, pan, busca por cidade)
FR15: Banda envia convite de conexão para outra banda
FR16: Banda aceita ou recusa convite de conexão
FR17: Banda visualiza suas conexões ativas
FR18: Banda desfaz uma conexão existente
FR19: Banda (com conexão ativa) cria e envia proposta de evento para venue
FR20: Venue cria proposta de evento selecionando bandas diretamente
FR21: Produtor cria proposta de evento selecionando venue e bandas
FR22: Venue aceita ou rejeita proposta de evento recebida
FR23: Usuário visualiza histórico de propostas enviadas e recebidas
FR24: Usuário cancela proposta antes da decisão final
FR25: Usuário inicia conversa de chat com outro usuário
FR26: Usuário envia e recebe mensagens em tempo real
FR27: Usuário visualiza histórico de conversas
FR28: Usuário recebe notificação in-app ao receber nova mensagem
FR29: Usuário recebe notificação in-app quando proposta é enviada, aceita ou rejeitada
FR30: Usuário denuncia mensagem de chat
FR31: Usuário cria mini landing page associada ao perfil
FR32: Usuário edita blocos de conteúdo da landing page (texto, imagens, links)
FR33: Landing page é acessível por URL pública
FR34: Visitante visualiza landing page sem estar autenticado
FR35: Admin visualiza métricas da plataforma (cadastros, propostas, shows fechados)
FR36: Admin modera e remove perfis que violam termos de uso
FR37: Admin visualiza e resolve denúncias de usuários
FR38: Admin bloqueia ou desbloqueia usuários

### NonFunctional Requirements

NFR01: Carregamento inicial do mapa < 2 segundos em conexão padrão
NFR02: Atualização de pins < 1 segundo
NFR03: Entrega de mensagens de chat < 500ms
NFR04: Respostas da API para ações do usuário < 1 segundo
NFR05: Todas as comunicações via HTTPS (TLS 1.2+)
NFR06: Mensagens de chat criptografadas em trânsito e em repouso (Active Record Encryption)
NFR07: Senhas armazenadas com bcrypt
NFR08: Tokens OAuth sem exposição no cliente
NFR09: Disponibilidade 99.5% uptime (< 4 horas de downtime/mês)
NFR10: Exclusão permanente de dados pessoais disponível (LGPD)

### Additional Requirements

- AR01: Rails 8 já inicializado como API-only — sem criar novo projeto; apenas configurar gems e banco
- AR02: PostgreSQL em todos os ambientes (dev, test, prod) — substituir SQLite3
- AR03: Gems a adicionar: rack-cors (ativar), bcrypt (ativar), devise, devise-jwt, omniauth-google-oauth2, omniauth-facebook, pg, geocoder, aasm
- AR04: Versionamento de API obrigatório: namespace /api/v1/ em todas as rotas autenticadas
- AR05: JWT no header Authorization: Bearer <token> para todos os endpoints autenticados
- AR06: ActionCable autenticado via JWT no query param token= em application_cable/connection.rb
- AR07: Active Record Encryption para Message#body — nunca texto plano no banco
- AR08: AASM para state machines: Connection (pending → accepted/rejected/dissolved) e EventProposal (draft → sent → accepted/rejected/cancelled)
- AR09: Geocoding assíncrono via Solid Queue (GeocodingJob) — nunca síncrono no controller
- AR10: LandingPage com campo slug único para rota pública GET /landing/:slug (fora do namespace /api/v1/)
- AR11: Cascade delete completo partindo de User para todos os dados associados (LGPD — FR05)
- AR12: Índices obrigatórios: profiles(latitude, longitude), profiles(map_visible), profiles(profile_type), messages(conversation_id), connections(initiator_id), connections(recipient_id)
- AR13: Formato de erro padrão em todos os endpoints: { error: "mensagem", code: "código" }
- AR14: DELETE /api/v1/account para exclusão permanente de conta (FR05)
- AR15: current_profile (não current_user) como helper de autenticação em todos os controllers

### UX Design Requirements

Nenhum documento de UX Design encontrado. Requisitos de UX não aplicáveis nesta etapa.

### FR Coverage Map

FR01: Epic 1 — Registro com e-mail e senha
FR02: Epic 1 — Registro via OAuth (Google/Facebook)
FR03: Epic 1 — Login com e-mail/senha ou OAuth
FR04: Epic 1 — Recuperação de senha
FR05: Epic 1 — Exclusão permanente de conta (LGPD)
FR06: Epic 1 — Aceite de termos de uso no cadastro
FR07: Epic 2 — Criação de perfil com tipo fixo
FR08: Epic 2 — Edição de informações do perfil
FR09: Epic 2 — Controle de visibilidade do pin no mapa
FR10: Epic 2 — Visualização de perfil público de outros usuários
FR11: Epic 2 — Mapa interativo com pins por cidade
FR12: Epic 2 — Clique em pin para ver perfil resumido
FR13: Epic 2 — Filtro de pins por tipo de entidade
FR14: Epic 2 — Navegação livre pelo mapa
FR15: Epic 3 — Envio de convite de conexão entre bandas
FR16: Epic 3 — Aceitar ou recusar convite de conexão
FR17: Epic 3 — Visualização de conexões ativas
FR18: Epic 3 — Desfazer uma conexão existente
FR19: Epic 4 — Banda (com conexão ativa) cria proposta para venue
FR20: Epic 4 — Venue cria proposta selecionando bandas
FR21: Epic 4 — Produtor cria proposta selecionando venue e bandas
FR22: Epic 4 — Venue aceita ou rejeita proposta
FR23: Epic 4 — Histórico de propostas enviadas e recebidas
FR24: Epic 4 — Cancelamento de proposta antes da decisão final
FR25: Epic 5 — Iniciar conversa de chat com outro usuário
FR26: Epic 5 — Enviar e receber mensagens em tempo real
FR27: Epic 5 — Visualizar histórico de conversas
FR28: Epic 5 — Notificação in-app ao receber nova mensagem
FR29: Epic 5 — Notificação in-app em mudanças de proposta
FR30: Epic 5 — Denúncia de mensagem de chat
FR31: Epic 6 — Criar mini landing page associada ao perfil
FR32: Epic 6 — Editar blocos de conteúdo da landing page
FR33: Epic 6 — Landing page acessível por URL pública
FR34: Epic 6 — Visitante acessa landing page sem autenticação
FR35: Epic 7 — Métricas da plataforma para admin
FR36: Epic 7 — Moderação e remoção de perfis
FR37: Epic 7 — Visualização e resolução de denúncias
FR38: Epic 7 — Bloqueio e desbloqueio de usuários

## Epic List

### Epic 1: Fundação Técnica & Autenticação
Usuários podem criar conta, fazer login (email/senha e OAuth), recuperar senha, aceitar termos, e excluir conta permanentemente. Toda a infraestrutura técnica do projeto está configurada e funcional.
**FRs cobertos:** FR01, FR02, FR03, FR04, FR05, FR06
**Reqs. técnicos:** AR01–AR15

### Epic 2: Perfis & Mapa de Descoberta Geográfica
Usuários podem criar e editar perfis com tipo fixo (banda, venue, produtor), aparecer no mapa interativo com pins por cidade, controlar visibilidade, descobrir e visualizar perfis de outros usuários.
**FRs cobertos:** FR07, FR08, FR09, FR10, FR11, FR12, FR13, FR14
**NFRs:** NFR01 (mapa < 2s), NFR02 (pins < 1s)
**Dependências:** Epic 1

### Epic 3: Sistema de Conexões entre Bandas
Bandas podem enviar convites de conexão para outras bandas, aceitar ou recusar, visualizar conexões ativas e desfazer conexões — criando a unidade formal de negociação do GarageDom.
**FRs cobertos:** FR15, FR16, FR17, FR18
**Dependências:** Epic 2

### Epic 4: Workflow de Propostas de Eventos
Qualquer ator (banda com conexão, venue ou produtor) pode criar e gerenciar propostas de eventos. Venues têm poder de aprovação final. Histórico de propostas visível para todos os participantes.
**FRs cobertos:** FR19, FR20, FR21, FR22, FR23, FR24
**Dependências:** Epic 2; Epic 3 (para fluxo banda-iniciador — FR19)

### Epic 5: Comunicação em Tempo Real
Usuários podem iniciar conversas, trocar mensagens em tempo real via chat criptografado, visualizar histórico, receber notificações in-app para mensagens e mudanças de proposta, e denunciar mensagens.
**FRs cobertos:** FR25, FR26, FR27, FR28, FR29, FR30
**NFRs:** NFR03 (chat < 500ms), NFR06 (criptografia)
**Dependências:** Epic 2

### Epic 6: Mini Landing Pages
Usuários podem criar e editar mini landing pages com blocos de conteúdo (texto, imagens, links), acessíveis por URL pública sem autenticação — vitrine profissional independente do perfil na plataforma.
**FRs cobertos:** FR31, FR32, FR33, FR34
**Dependências:** Epic 2

### Epic 7: Administração & Moderação
A equipe interna pode acessar painel de métricas (cadastros, propostas, shows fechados), moderar e remover perfis, visualizar e resolver denúncias de usuários, e bloquear/desbloquear contas.
**FRs cobertos:** FR35, FR36, FR37, FR38
**Dependências:** Epic 1, Epic 2, Epic 5

## Epic 1: Fundação Técnica & Autenticação

Usuários podem criar conta, fazer login (email/senha e OAuth), recuperar senha, aceitar termos e excluir conta permanentemente. Toda a infraestrutura técnica está configurada e funcional.

### Story 1.1: Setup Técnico do Projeto

Como desenvolvedor,
quero o projeto configurado com PostgreSQL, gems essenciais, CORS e infraestrutura de JWT,
para que todas as features sejam construídas sobre uma base consistente e funcional.

**Acceptance Criteria:**

**Dado** que o projeto Rails 8 está inicializado em modo API-only
**Quando** as gems são adicionadas (rack-cors, bcrypt, devise, devise-jwt, omniauth-google-oauth2, omniauth-facebook, pg, geocoder, aasm) e `bundle install` é executado
**Então** todas as gems instalam sem conflitos
**E** `database.yml` está configurado para PostgreSQL em dev, test e prod
**E** `rack-cors` está configurado em `config/initializers/cors.rb` aceitando o domínio do frontend
**E** `devise` está instalado e configurado para JWT via `devise-jwt`
**E** Active Record Encryption está configurado em `config/initializers/encryption.rb`
**E** `rails db:create && rails db:migrate` executa sem erros

### Story 1.2: Registro de Usuário com E-mail e Senha

Como visitante,
quero criar uma conta com e-mail e senha aceitando os termos de uso,
para que eu possa acessar a plataforma GarageDom.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/auth/register` com `email`, `password`, `password_confirmation` e `terms_accepted: true` válidos
**Quando** a requisição é processada
**Então** um usuário é criado com senha criptografada (bcrypt)
**E** a resposta retorna HTTP 201 com JWT token no header `Authorization` e no body

**Dado** `terms_accepted: false`
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Termos de uso devem ser aceitos", code: "terms_required" }`

**Dado** e-mail já cadastrado
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "E-mail já cadastrado", code: "email_taken" }`

**Dado** campos obrigatórios ausentes ou senha com menos de 8 caracteres
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "...", code: "unprocessable_entity" }`

### Story 1.3: Login e Logout com JWT

Como usuário cadastrado,
quero fazer login com e-mail e senha e encerrar minha sessão,
para que eu possa acessar e sair da minha conta com segurança.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/auth/login` com credenciais válidas
**Quando** a requisição é processada
**Então** HTTP 200 com JWT token no header `Authorization: Bearer <token>` e no body

**Dado** um `DELETE /api/v1/auth/logout` com JWT válido no header
**Quando** a requisição é processada
**Então** o token é invalidado (JTI blocklist via devise-jwt)
**E** HTTP 200 com mensagem de confirmação

**Dado** credenciais inválidas no login
**Quando** a requisição é processada
**Então** HTTP 401 com `{ error: "E-mail ou senha inválidos", code: "invalid_credentials" }`

### Story 1.4: Autenticação OAuth (Google e Facebook)

Como visitante,
quero criar conta ou fazer login via OAuth do Google ou Facebook,
para que eu possa acessar a plataforma sem precisar criar uma senha separada.

**Acceptance Criteria:**

**Dado** que o fluxo OAuth do Google ou Facebook é concluído com sucesso
**Quando** o callback chega em `GET /api/v1/auth/google_oauth2/callback` ou `/api/v1/auth/facebook/callback`
**Então** o usuário é criado (novo) ou encontrado (existente) pelo UID do provider
**E** JWT token é retornado no body e no header `Authorization`
**E** HTTP 201 para novo usuário, HTTP 200 para login existente

**Dado** falha no fluxo OAuth (token inválido, permissão negada)
**Quando** o callback chega
**Então** HTTP 422 com `{ error: "Autenticação OAuth falhou", code: "oauth_failed" }`

### Story 1.5: Recuperação de Senha por E-mail

Como usuário cadastrado,
quero solicitar redefinição de senha via e-mail,
para que eu possa recuperar o acesso à minha conta caso esqueça a senha.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/auth/password` com e-mail cadastrado
**Quando** a requisição é processada
**Então** e-mail de redefinição é enviado (Devise mailer)
**E** HTTP 200 — mesmo se o e-mail não existir (previne enumeração)

**Dado** um `PUT /api/v1/auth/password` com token válido e nova senha
**Quando** a requisição é processada
**Então** a senha é atualizada
**E** HTTP 200 com confirmação

**Dado** token expirado ou inválido
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Token inválido ou expirado", code: "invalid_reset_token" }`

### Story 1.6: Exclusão Permanente de Conta (LGPD)

Como usuário cadastrado,
quero excluir minha conta e todos os meus dados permanentemente,
para que eu possa exercer meu direito de apagamento conforme a LGPD.

**Acceptance Criteria:**

**Dado** um `DELETE /api/v1/account` com JWT válido no header
**Quando** a requisição é processada
**Então** o usuário e todos os dados associados são excluídos em cascata (perfil, conexões, propostas, conversas, mensagens, notificações, landing pages, denúncias)
**E** o JWT token é invalidado imediatamente
**E** HTTP 200 com confirmação de exclusão

**Dado** a exclusão foi processada
**Quando** qualquer requisição subsequente usa o mesmo token
**Então** HTTP 401 com `{ error: "Token inválido", code: "unauthorized" }`

## Epic 2: Perfis & Mapa de Descoberta Geográfica

Usuários podem criar e editar perfis, aparecer no mapa com pins, controlar visibilidade, e descobrir outros perfis geograficamente.

### Story 2.1: Criação de Perfil com Geocoding

Como usuário autenticado,
quero criar meu perfil com tipo fixo (banda, venue ou produtor) e cidade,
para que eu apareça no mapa e seja descoberto por outros usuários.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/profiles` com JWT válido, `profile_type` (band/venue/producer), nome, cidade e campos opcionais (bio, gênero musical)
**Quando** a requisição é processada
**Então** o perfil é criado com `map_visible: true` por padrão
**E** um `GeocodingJob` é enfileirado via Solid Queue para converter a cidade em `latitude` e `longitude`
**E** HTTP 201 com dados do perfil criado

**Dado** `profile_type` inválido ou ausente
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Tipo de perfil inválido", code: "invalid_profile_type" }`

**Dado** usuário já possui um perfil
**Quando** tenta criar outro
**Então** HTTP 422 com `{ error: "Usuário já possui perfil", code: "profile_already_exists" }`

### Story 2.2: Edição de Perfil

Como usuário autenticado com perfil criado,
quero editar as informações do meu perfil (nome, bio, gênero musical, cidade, membros, fotos),
para que minha apresentação na plataforma esteja sempre atualizada.

**Acceptance Criteria:**

**Dado** um `PATCH /api/v1/profiles/:id` com JWT válido e campos a atualizar
**Quando** a cidade é alterada
**Então** um novo `GeocodingJob` é enfileirado para atualizar `latitude` e `longitude`
**E** HTTP 200 com perfil atualizado

**Dado** `PATCH /api/v1/profiles/:id` com JWT de outro usuário
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

**Dado** campos com formato inválido
**Quando** a requisição é processada
**Então** HTTP 422 com detalhes do erro

### Story 2.3: Controle de Visibilidade no Mapa (LGPD)

Como usuário autenticado,
quero controlar se meu perfil aparece no mapa público,
para que eu possa exercer meu direito de privacidade conforme a LGPD.

**Acceptance Criteria:**

**Dado** um `PATCH /api/v1/profiles/:id` com `{ map_visible: false }` e JWT válido do dono
**Quando** a requisição é processada
**Então** `map_visible` é atualizado para `false`
**E** o perfil deixa de aparecer nas respostas de `GET /api/v1/map/pins`
**E** HTTP 200 com perfil atualizado

**Dado** `{ map_visible: true }`
**Quando** a requisição é processada
**Então** o perfil volta a aparecer no mapa

### Story 2.4: Visualização de Perfil Público

Como qualquer usuário autenticado,
quero visualizar o perfil público de outros usuários,
para que eu possa conhecer bandas, venues e produtores antes de me conectar.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/profiles/:id` com JWT válido
**Quando** o perfil existe
**Então** HTTP 200 com dados públicos do perfil (nome, bio, profile_type, cidade, gênero musical, map_visible)

**Dado** `profile_id` inexistente
**Quando** a requisição é processada
**Então** HTTP 404 com `{ error: "Perfil não encontrado", code: "not_found" }`

### Story 2.5: Endpoint de Pins do Mapa

Como qualquer usuário autenticado,
quero ver pins de bandas, venues e produtores no mapa e filtrá-los por tipo,
para que eu possa descobrir músicos e espaços geograficamente.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/map/pins` com JWT válido
**Quando** a requisição é processada
**Então** HTTP 200 com array de perfis visíveis (`map_visible: true`) contendo apenas: `id`, `name`, `profile_type`, `latitude`, `longitude`
**E** perfis com `latitude` e `longitude` nulos (geocoding pendente) são excluídos da resposta
**E** tempo de resposta < 1 segundo (índices em `map_visible`, `latitude`, `longitude`)

**Dado** query param `?profile_type=band`
**Quando** a requisição é processada
**Então** apenas perfis com `profile_type: "band"` são retornados

**Dado** query param `?city=Jundiai`
**Quando** a requisição é processada
**Então** apenas perfis da cidade correspondente são retornados

## Epic 3: Sistema de Conexões entre Bandas

Bandas podem enviar convites de conexão para outras bandas, aceitar ou recusar, visualizar conexões ativas e desfazer conexões — criando a unidade formal de negociação do GarageDom.

### Story 3.1: Enviar Convite de Conexão

Como banda autenticada,
quero enviar um convite de conexão para outra banda,
para que possamos nos tornar parceiros formais de negociação na plataforma.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/connections` com JWT de perfil `band` e `recipient_id` de outra banda
**Quando** a requisição é processada
**Então** uma `Connection` é criada com estado `pending`
**E** uma notificação in-app é enviada para a banda destinatária via `NotificationsChannel`
**E** HTTP 201 com dados da conexão (`id`, `initiator_id`, `recipient_id`, `state: "pending"`)

**Dado** o `current_profile` não é do tipo `band`
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Apenas bandas podem criar conexões", code: "forbidden" }`

**Dado** o `recipient_id` não é do tipo `band`
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Conexões são permitidas apenas entre bandas", code: "invalid_recipient" }`

**Dado** já existe uma conexão ativa ou pendente entre as duas bandas
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Conexão já existe", code: "connection_already_exists" }`

### Story 3.2: Responder a Convite de Conexão

Como banda autenticada,
quero aceitar ou recusar um convite de conexão recebido,
para que eu controle com quais bandas me associo formalmente.

**Acceptance Criteria:**

**Dado** um `PATCH /api/v1/connections/:id/accept` com JWT da banda destinatária
**Quando** a conexão está no estado `pending`
**Então** o estado muda para `accepted` via AASM
**E** notificação in-app é enviada para a banda iniciadora
**E** HTTP 200 com conexão atualizada

**Dado** um `PATCH /api/v1/connections/:id/reject` com JWT da banda destinatária
**Quando** a conexão está no estado `pending`
**Então** o estado muda para `rejected` via AASM
**E** notificação in-app é enviada para a banda iniciadora
**E** HTTP 200 com conexão atualizada

**Dado** JWT de um perfil que não é o destinatário da conexão
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

**Dado** conexão não está no estado `pending`
**Quando** tenta aceitar ou recusar
**Então** HTTP 422 com `{ error: "Transição de estado inválida", code: "invalid_transition" }`

### Story 3.3: Listar Conexões Ativas

Como banda autenticada,
quero visualizar minhas conexões ativas,
para que eu saiba com quais bandas posso criar propostas de eventos em conjunto.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/connections` com JWT de perfil `band`
**Quando** a requisição é processada
**Então** HTTP 200 com array de conexões onde `current_profile` é iniciador ou destinatário e estado é `accepted`
**E** cada item contém: `id`, `state`, dados do perfil parceiro (`id`, `name`, `profile_type`)

**Dado** um `GET /api/v1/connections?state=pending`
**Quando** a requisição é processada
**Então** retorna apenas convites pendentes relacionados ao `current_profile`

### Story 3.4: Desfazer Conexão

Como banda autenticada,
quero desfazer uma conexão ativa com outra banda,
para que eu possa encerrar uma parceria que não faz mais sentido.

**Acceptance Criteria:**

**Dado** um `DELETE /api/v1/connections/:id` com JWT de um dos perfis da conexão
**Quando** a conexão está no estado `accepted`
**Então** o estado muda para `dissolved` via AASM
**E** notificação in-app é enviada para o perfil parceiro
**E** HTTP 200 com confirmação

**Dado** JWT de um perfil que não pertence à conexão
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

**Dado** conexão não está no estado `accepted`
**Quando** tenta desfazer
**Então** HTTP 422 com `{ error: "Transição de estado inválida", code: "invalid_transition" }`

## Epic 4: Workflow de Propostas de Eventos

Qualquer ator (banda com conexão, venue ou produtor) pode criar e gerenciar propostas de eventos. Venues têm poder de aprovação final. Histórico de propostas visível para todos os participantes.

### Story 4.1: Criar Proposta — Fluxo Banda (com Conexão)

Como banda autenticada com conexão ativa,
quero criar e enviar uma proposta de evento para um venue,
para que possamos negociar um show em conjunto com nossa banda parceira.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/event_proposals` com JWT de perfil `band`, `venue_id` válido, `connection_id` de conexão `accepted` da qual a banda faz parte, data proposta e cachê estimado
**Quando** a requisição é processada
**Então** uma `EventProposal` é criada no estado `sent` via AASM
**E** `EventProposalParticipant` é criado para cada banda da conexão
**E** notificação in-app é enviada ao venue via `NotificationsChannel`
**E** HTTP 201 com dados da proposta

**Dado** `connection_id` de uma conexão que não está no estado `accepted`
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Conexão não está ativa", code: "inactive_connection" }`

**Dado** `current_profile` não faz parte da conexão informada
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

### Story 4.2: Criar Proposta — Fluxo Venue e Produtor

Como venue ou produtor autenticado,
quero criar uma proposta de evento selecionando bandas (e venue, no caso do produtor),
para que eu possa orquestrar um evento completo pela plataforma.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/event_proposals` com JWT de perfil `venue`, `band_ids` (array com ≥1 banda) e dados do evento
**Quando** a requisição é processada
**Então** `EventProposal` criada no estado `sent`
**E** `EventProposalParticipant` criado para cada banda selecionada
**E** notificações in-app enviadas para cada banda via `NotificationsChannel`
**E** HTTP 201 com dados da proposta

**Dado** um `POST /api/v1/event_proposals` com JWT de perfil `producer`, `venue_id` e `band_ids`
**Quando** a requisição é processada
**Então** `EventProposal` criada no estado `sent` com venue e bandas como participantes
**E** notificações enviadas para venue e todas as bandas
**E** HTTP 201 com dados da proposta

**Dado** `band_ids` vazio ou inválido
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Selecione ao menos uma banda", code: "unprocessable_entity" }`

### Story 4.3: Venue Responde à Proposta

Como venue autenticado,
quero aceitar ou rejeitar uma proposta de evento recebida,
para que eu exerça meu poder de aprovação final sobre os shows no meu espaço.

**Acceptance Criteria:**

**Dado** um `PATCH /api/v1/event_proposals/:id/accept` com JWT do venue da proposta
**Quando** a proposta está no estado `sent`
**Então** estado muda para `accepted` via AASM
**E** notificações in-app enviadas para todos os participantes (bandas e produtor se houver)
**E** HTTP 200 com proposta atualizada

**Dado** um `PATCH /api/v1/event_proposals/:id/reject` com JWT do venue
**Quando** a proposta está no estado `sent`
**Então** estado muda para `rejected` via AASM
**E** notificações in-app enviadas para todos os participantes
**E** HTTP 200 com proposta atualizada

**Dado** JWT de perfil que não é o venue da proposta
**Quando** tenta aceitar ou rejeitar
**Então** HTTP 403 com `{ error: "Apenas o venue pode responder à proposta", code: "forbidden" }`

**Dado** proposta não está no estado `sent`
**Quando** tenta responder
**Então** HTTP 422 com `{ error: "Transição de estado inválida", code: "invalid_transition" }`

### Story 4.4: Cancelar Proposta

Como usuário autenticado participante de uma proposta,
quero cancelar uma proposta antes da decisão final do venue,
para que eu possa desistir de um evento que não é mais viável.

**Acceptance Criteria:**

**Dado** um `PATCH /api/v1/event_proposals/:id/cancel` com JWT de qualquer participante da proposta
**Quando** a proposta está no estado `sent`
**Então** estado muda para `cancelled` via AASM
**E** notificações in-app enviadas para todos os demais participantes
**E** HTTP 200 com proposta atualizada

**Dado** proposta já no estado `accepted`, `rejected` ou `cancelled`
**Quando** tenta cancelar
**Então** HTTP 422 com `{ error: "Transição de estado inválida", code: "invalid_transition" }`

**Dado** JWT de perfil que não é participante da proposta
**Quando** tenta cancelar
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

### Story 4.5: Histórico de Propostas

Como usuário autenticado,
quero visualizar o histórico de propostas enviadas e recebidas,
para que eu possa acompanhar o status de todas as negociações em andamento.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/event_proposals` com JWT válido
**Quando** a requisição é processada
**Então** HTTP 200 com propostas onde `current_profile` é iniciador ou participante
**E** cada item contém: `id`, `state`, `proposed_date`, dados do venue, lista de bandas participantes, `initiator_type`

**Dado** query param `?state=sent`
**Quando** a requisição é processada
**Então** retorna apenas propostas no estado especificado

**Dado** um `GET /api/v1/event_proposals/:id` com JWT de participante
**Quando** a requisição é processada
**Então** HTTP 200 com todos os detalhes da proposta

**Dado** JWT de perfil não participante da proposta
**Quando** tenta acessar `GET /api/v1/event_proposals/:id`
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

## Epic 5: Comunicação em Tempo Real

Usuários podem iniciar conversas, trocar mensagens em tempo real via chat criptografado, visualizar histórico, receber notificações in-app e denunciar mensagens.

### Story 5.1: Iniciar Conversa e Histórico

Como usuário autenticado,
quero iniciar uma conversa com outro usuário e visualizar meu histórico de conversas,
para que eu possa me comunicar diretamente com bandas, venues e produtores na plataforma.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/conversations` com JWT válido e `recipient_id` de outro perfil
**Quando** não existe conversa entre os dois perfis
**Então** uma `Conversation` é criada com dois `ConversationParticipant`
**E** HTTP 201 com dados da conversa (`id`, lista de participantes)

**Dado** uma conversa já existe entre os dois perfis
**Quando** `POST /api/v1/conversations` é chamado novamente
**Então** a conversa existente é retornada (sem duplicação)
**E** HTTP 200

**Dado** um `GET /api/v1/conversations` com JWT válido
**Quando** a requisição é processada
**Então** HTTP 200 com lista de conversas do `current_profile`, ordenadas por última mensagem
**E** cada item contém: `id`, dados do outro participante, preview da última mensagem, `unread_count`

### Story 5.2: Chat em Tempo Real via ActionCable

Como usuário autenticado em uma conversa,
quero enviar e receber mensagens em tempo real,
para que a comunicação com outros usuários seja imediata e fluida.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/conversations/:id/messages` com JWT válido e `body` da mensagem
**Quando** a requisição é processada
**Então** a mensagem é persistida com `body` criptografado via Active Record Encryption
**E** a mensagem é transmitida via `ChatChannel.broadcast_to(conversation)` para todos os participantes conectados
**E** HTTP 201 com dados da mensagem (`id`, `body` descriptografado, `sender_id`, `created_at`)
**E** tempo total de entrega < 500ms

**Dado** um cliente conectado ao `ChatChannel` com `conversation_id` válido e JWT no query param `token=`
**Quando** outro participante envia uma mensagem
**Então** o cliente recebe o evento `new_message` com os dados da mensagem em tempo real

**Dado** `body` vazio ou ausente
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Mensagem não pode ser vazia", code: "unprocessable_entity" }`

**Dado** JWT de perfil não participante da conversa
**Quando** tenta enviar mensagem
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

**Dado** um `GET /api/v1/conversations/:id/messages` com JWT de participante
**Quando** a requisição é processada
**Então** HTTP 200 com histórico de mensagens paginado, `body` descriptografado

### Story 5.3: Notificações In-App via ActionCable

Como usuário autenticado,
quero receber notificações em tempo real sobre novas mensagens e mudanças em propostas,
para que eu seja informado imediatamente de eventos relevantes na plataforma.

**Acceptance Criteria:**

**Dado** um cliente conectado ao `NotificationsChannel` com JWT no query param `token=`
**Quando** outro usuário envia uma mensagem para uma conversa do `current_profile`
**Então** o cliente recebe o evento `new_message` com `conversation_id` e preview da mensagem

**Dado** uma proposta onde `current_profile` é participante muda de estado
**Quando** o estado é atualizado (sent/accepted/rejected/cancelled)
**Então** o cliente conectado recebe o evento correspondente (`proposal_sent`, `proposal_accepted`, `proposal_rejected`, `proposal_cancelled`) com `proposal_id`

**Dado** um `GET /api/v1/notifications` com JWT válido
**Quando** a requisição é processada
**Então** HTTP 200 com lista de notificações do `current_profile` ordenadas por `created_at` desc

**Dado** um `PATCH /api/v1/notifications/:id/read` com JWT do dono
**Quando** a requisição é processada
**Então** a notificação é marcada como lida
**E** HTTP 200

### Story 5.4: Denúncia de Mensagem

Como usuário autenticado,
quero denunciar uma mensagem de chat inapropriada,
para que a equipe de moderação possa analisar e tomar as medidas cabíveis.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/messages/:id/reports` com JWT válido e `reason` da denúncia
**Quando** a requisição é processada
**Então** um `Report` é criado com `reportable_type: "Message"`, `reportable_id`, `reporter_id` e `reason`
**E** HTTP 201 com dados da denúncia

**Dado** o `current_profile` já denunciou a mesma mensagem
**Quando** tenta denunciar novamente
**Então** HTTP 422 com `{ error: "Você já denunciou esta mensagem", code: "already_reported" }`

**Dado** JWT de perfil não participante da conversa onde a mensagem está
**Quando** tenta denunciar
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

## Epic 6: Mini Landing Pages

Usuários podem criar e editar mini landing pages com blocos de conteúdo, acessíveis por URL pública sem autenticação — vitrine profissional independente do perfil na plataforma.

### Story 6.1: Criar Landing Page com Slug Público

Como usuário autenticado com perfil,
quero criar uma mini landing page associada ao meu perfil com URL pública única,
para que visitantes possam me encontrar e conhecer meu trabalho sem precisar de conta.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/landing_pages` com JWT válido e `slug` desejado
**Quando** a requisição é processada
**Então** uma `LandingPage` é criada associada ao `current_profile`
**E** `slug` é normalizado (lowercase, hífens, sem espaços) e validado como único
**E** HTTP 201 com dados da landing page incluindo a URL pública `/landing/:slug`

**Dado** `slug` já em uso por outro perfil
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Este endereço já está em uso", code: "slug_taken" }`

**Dado** `current_profile` já possui uma landing page
**Quando** tenta criar outra
**Então** HTTP 422 com `{ error: "Perfil já possui landing page", code: "landing_page_exists" }`

### Story 6.2: Editar Blocos de Conteúdo

Como usuário autenticado dono de uma landing page,
quero adicionar, editar e reordenar blocos de conteúdo (texto, imagens, links),
para que eu possa personalizar minha vitrine profissional na plataforma.

**Acceptance Criteria:**

**Dado** um `POST /api/v1/landing_pages/:id/blocks` com JWT do dono, `block_type` (text/image/link), `content` e `position`
**Quando** a requisição é processada
**Então** um `LandingPageBlock` é criado associado à landing page
**E** HTTP 201 com dados do bloco

**Dado** um `PATCH /api/v1/landing_pages/:id/blocks/:block_id` com JWT do dono e campos a atualizar
**Quando** a requisição é processada
**Então** o bloco é atualizado
**E** HTTP 200 com bloco atualizado

**Dado** um `DELETE /api/v1/landing_pages/:id/blocks/:block_id` com JWT do dono
**Quando** a requisição é processada
**Então** o bloco é removido
**E** HTTP 200

**Dado** `block_type` inválido
**Quando** a requisição é processada
**Então** HTTP 422 com `{ error: "Tipo de bloco inválido", code: "invalid_block_type" }`

**Dado** JWT de perfil que não é dono da landing page
**Quando** tenta criar/editar/deletar bloco
**Então** HTTP 403 com `{ error: "Acesso negado", code: "forbidden" }`

### Story 6.3: Acesso Público à Landing Page

Como visitante (autenticado ou não),
quero acessar a landing page de um usuário pela URL pública,
para que eu possa conhecer seu trabalho sem precisar criar uma conta.

**Acceptance Criteria:**

**Dado** um `GET /landing/:slug` sem JWT (sem autenticação)
**Quando** o `slug` existe e a landing page está associada a um perfil ativo
**Então** HTTP 200 com todos os dados públicos da landing page: dados do perfil dono, blocos ordenados por `position`

**Dado** `slug` inexistente
**Quando** a requisição é processada
**Então** HTTP 404 com `{ error: "Página não encontrada", code: "not_found" }`

**Dado** a rota `/landing/:slug` é acessada
**Quando** processada
**Então** nenhum middleware de autenticação é aplicado (rota pública fora do namespace `/api/v1/`)

## Epic 7: Administração & Moderação

A equipe interna pode acessar painel de métricas, moderar e remover perfis, visualizar e resolver denúncias de usuários, e bloquear/desbloquear contas.

### Story 7.1: Painel de Métricas da Plataforma

Como administrador da plataforma,
quero visualizar métricas de uso (cadastros, propostas, shows fechados),
para que eu possa acompanhar o crescimento e a saúde da plataforma GarageDom.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/admin/dashboard` com JWT de perfil `admin`
**Quando** a requisição é processada
**Então** HTTP 200 com métricas agregadas: total de usuários por `profile_type`, total de propostas por estado, total de shows fechados (propostas `accepted`), total de conexões ativas, cidades distintas com perfis visíveis no mapa

**Dado** JWT de perfil que não é `admin`
**Quando** tenta acessar qualquer rota `/api/v1/admin/`
**Então** HTTP 403 com `{ error: "Acesso restrito a administradores", code: "forbidden" }`

### Story 7.2: Moderação de Perfis e Bloqueio de Usuários

Como administrador da plataforma,
quero moderar perfis que violam os termos de uso e bloquear ou desbloquear usuários,
para que eu possa manter a qualidade e segurança da comunidade GarageDom.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/admin/profiles` com JWT `admin`
**Quando** a requisição é processada
**Então** HTTP 200 com lista paginada de todos os perfis, incluindo `blocked: true/false`

**Dado** um `DELETE /api/v1/admin/profiles/:id` com JWT `admin`
**Quando** a requisição é processada
**Então** o perfil e seus dados associados são removidos
**E** HTTP 200 com confirmação

**Dado** um `PATCH /api/v1/admin/profiles/:id/block` com JWT `admin`
**Quando** a requisição é processada
**Então** o campo `blocked` do usuário é definido como `true`
**E** todos os tokens JWT ativos do usuário são invalidados
**E** HTTP 200 com dados atualizados

**Dado** um `PATCH /api/v1/admin/profiles/:id/unblock` com JWT `admin`
**Quando** a requisição é processada
**Então** o campo `blocked` é definido como `false`
**E** HTTP 200 com dados atualizados

**Dado** usuário bloqueado tenta fazer login
**Quando** a requisição é processada
**Então** HTTP 403 com `{ error: "Conta bloqueada", code: "account_blocked" }`

### Story 7.3: Gestão de Denúncias

Como administrador da plataforma,
quero visualizar e resolver denúncias de usuários sobre mensagens e perfis,
para que eu possa investigar e agir sobre comportamentos inadequados na plataforma.

**Acceptance Criteria:**

**Dado** um `GET /api/v1/admin/reports` com JWT `admin`
**Quando** a requisição é processada
**Então** HTTP 200 com lista paginada de denúncias incluindo: `id`, `reportable_type`, `reportable_id`, dados do denunciante, `reason`, `status`, `created_at`

**Dado** query param `?status=pending`
**Quando** a requisição é processada
**Então** retorna apenas denúncias com status `pending`

**Dado** um `PATCH /api/v1/admin/reports/:id/resolve` com JWT `admin` e `resolution_note`
**Quando** a requisição é processada
**Então** o `status` da denúncia muda para `resolved`
**E** `resolved_by` é registrado com o ID do admin
**E** HTTP 200 com denúncia atualizada

**Dado** um `PATCH /api/v1/admin/reports/:id/dismiss` com JWT `admin`
**Quando** a requisição é processada
**Então** o `status` muda para `dismissed`
**E** HTTP 200 com denúncia atualizada
