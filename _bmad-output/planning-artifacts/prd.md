---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish']
inputDocuments: []
workflowType: 'prd'
classification:
  projectType: 'saas_marketplace_3sided'
  domain: 'entertainment_music'
  complexity: 'high'
  projectContext: 'greenfield'
---

# Product Requirements Document - GarageDom

**Author:** Garagedom
**Date:** 2026-04-03

## Sumário Executivo

O GarageDom é um marketplace SaaS 3-sided dedicado à indústria musical independente, conectando bandas, casas de shows e produtores de eventos em um ecossistema profissional de orquestração de eventos. O produto resolve a ausência de infraestrutura formal no mercado underground musical: artistas e venues dependem exclusivamente de conexões pessoais e redes sociais para negociar shows, limitando alcance geográfico e profissionalização do setor.

**Diferencial central:** o GarageDom não é rede social — é ferramenta de trabalho. Três inovações distinguem o produto: (1) **conexões** como unidade formal de negociação entre artistas; (2) **workflow multi-iniciador** onde qualquer dos 3 atores pode orquestrar um evento, com a Casa de Shows retendo poder de aprovação final; (3) **descoberta geográfica** via mapa com pins por cidade, tornando artistas visíveis sem depender de algoritmos ou seguidores.

**Visão de longo prazo:** expandir para distribuição digital (lançamento em plataformas de streaming) e venda de ingressos, tornando o GarageDom o ecossistema completo da música independente brasileira.

**Classificação:** SaaS Marketplace 3-sided | Domínio: Entretenimento / Música Independente | Complexidade: Alta | Greenfield

## Critérios de Sucesso

### Sucesso do Usuário

- **Banda:** fechou pelo menos 1 show via plataforma; formou conexão com outra banda e ofertaram juntos; foi descoberta por venue pelo mapa sem ter iniciado o contato
- **Casa de Shows:** montou lineup completo usando só a plataforma; descobriu bandas fora da sua rede habitual
- **Produtor:** orquestrou evento completo (venue + artistas) via plataforma; fechou evento com partes sem contato prévio

### Sucesso do Negócio

Metas para os primeiros 6 meses após lançamento:

- 500 bandas cadastradas
- 100 casas de shows cadastradas
- 50 produtores cadastrados
- 50 shows fechados pela plataforma
- 20 cidades com pelo menos 1 pin no mapa
- Taxa de conversão proposta → show fechado ≥ 20%
- Retenção de 30 dias após cadastro ≥ 40%

### Sucesso Técnico

- Carregamento inicial do mapa < 2 segundos; atualização de pins < 1 segundo
- Disponibilidade: 99.5% uptime (< 4 horas de downtime/mês)

## Escopo do Produto

### MVP — Fase 1

- Cadastro e perfis dos 3 tipos de usuário (banda, casa de shows, produtor)
- Autenticação email/senha + OAuth (Google + Facebook)
- Mapa interativo com Leaflet (pins por cidade, filtro por tipo)
- Sistema de conexões entre artistas
- Workflow de proposta de eventos (3 fluxos de iniciação)
- Chat em tempo real via ActionCable
- Mini landing page simples (builder editável, gratuito)
- Notificações in-app via ActionCable
- Painel administrativo básico (moderação + métricas)
- Controle de visibilidade no mapa (LGPD)

**Estratégia de lançamento:** foco inicial em Jundiaí, SP, com network seed existente para atingir densidade mínima de pins antes de expandir.

### Fase 2 — Crescimento

- Landing page premium (versão paga — primeiro modelo de monetização)
- Avaliações e sistema de reputação de bandas/venues
- Notificações por e-mail
- Filtros avançados no mapa (gênero musical, disponibilidade)
- Expansão geográfica nacional
- App mobile (iOS/Android)

### Fase 3 — Expansão

- Distribuição digital (Spotify, Deezer e demais plataformas de streaming)
- Venda de ingressos para shows independentes
- Expansão para teatro, eventos diversos e outros tipos de artistas
- Tiers de assinatura completos

## Jornadas do Usuário

### Jornada 1 — Banda: O Primeiro Show Fora da Cidade

**Persona:** Lucas, guitarrista de banda de rock independente em Campinas, SP. 2 anos de estrada, nunca tocou fora da cidade.

**Cena inicial:** Lucas cadastra a banda no GarageDom e vê o pin aparecer no mapa de Campinas.

**Ação:** Navegando pelo mapa, encontra venue em SP. Convida outra banda de Campinas para formar uma conexão e juntos enviam proposta de noite dupla.

**Momento de valor:** Venue aceita. Lucas abre o chat e negocia os detalhes diretamente pela plataforma.

**Nova realidade:** Primeiro show em SP confirmado. Perfil com histórico visível para outras casas.

---

### Jornada 2 — Casa de Shows: Montando uma Noite Especial

**Persona:** Carol, gerente de casa de shows em BH. Quer noite temática rock + blues, mas não tem banda de blues na rede pessoal.

**Cena inicial:** Carol filtra bandas de blues no mapa do GarageDom em BH e cidades próximas.

**Ação:** Seleciona duas bandas, cria conexão entre elas e monta proposta de evento com data e cachê estimado.

**Momento de valor:** Ambas aceitam. Lineup montado com bandas nunca contatadas antes.

**Nova realidade:** GarageDom vira ferramenta de curadoria de lineup, não apenas agenda de conhecidos.

---

### Jornada 3 — Produtor: Orquestrando um Evento do Zero

**Persona:** Roberto, produtor independente no RJ. Ideia de evento temático sem venue fixo nem bandas confirmadas.

**Cena inicial:** Roberto usa o mapa para encontrar venues com capacidade para 300 pessoas no RJ.

**Ação:** Escolhe venue, seleciona 3 bandas de gêneros distintos, monta proposta completa e envia para aprovação.

**Momento de valor:** Venue faz contraproposta via chat. Evento fechado sem nenhum contato prévio com as partes.

**Nova realidade:** GarageDom é o escritório de produção — descoberta, negociação e comunicação em um lugar.

---

### Jornada 4 — Administrador da Plataforma

**Persona:** Equipe interna GarageDom, responsável por operações e qualidade.

**Ações:** Moderação e aprovação de perfis; gestão de denúncias; monitoramento de métricas (cadastros, propostas, shows fechados); bloqueio de usuários com comportamento irregular.

---

### Mapeamento Jornada → Capacidades

| Jornada | Capacidades Necessárias |
|---|---|
| Banda | Cadastro, mapa, conexões, proposta, chat, notificações |
| Casa de Shows | Filtro no mapa, conexão entre terceiros, proposta, aprovação/rejeição |
| Produtor | Seleção multi-entidade, proposta composta, chat |
| Admin | Painel de métricas, moderação, denúncias, bloqueio |

## Inovação e Diferenciação

### Três Padrões Inéditos no Mercado

**1. Conexões como Unidade de Negociação**
Bandas formam agrupamentos formais que se tornam entidades de negociação. Nenhuma plataforma de booking musical trata o agrupamento de artistas como primitivo do sistema.

**2. Workflow de Proposta Multi-Iniciador**
Qualquer dos 3 atores pode iniciar e orquestrar um evento. Marketplaces tradicionais têm lados fixos de oferta e demanda. A Casa de Shows retém aprovação final, refletindo a realidade do mercado.

**3. Descoberta Geográfica Dedicada**
Mapa com pins por cidade torna artistas descobríveis sem depender de algoritmos de relevância, seguidores ou rede pessoal.

### Paisagem Competitiva

Sympla, Ticket360 e redes sociais focam em eventos já fechados ou visibilidade de redes existentes. Nenhuma oferece agrupamento formal de artistas, fluxo multi-iniciador ou camada de descoberta geográfica dedicada ao mercado musical independente.

### Validação e Mitigação

- **Conexões:** Monitorar uso do recurso vs. negociação individual nos primeiros 3 meses. Se preferência for individual, plataforma funciona como marketplace convencional.
- **Multi-iniciador:** Medir qual ator inicia mais propostas para calibrar UX por perfil.
- **Mapa:** Medir proporção de conexões originadas por descoberta geográfica vs. busca direta.

## Requisitos de Plataforma

### Stack Técnica

- **Backend:** Ruby on Rails (API)
- **Frontend:** React (consome API Rails)
- **Tempo Real:** ActionCable (WebSockets nativo do Rails) — chat e notificações in-app
- **Mapa:** Leaflet (open source)
- **Autenticação:** Devise (email/senha) + Omniauth (Google, Facebook)

### Modelo de Perfil

- Um perfil por entidade — sem sub-contas ou multi-usuários no MVP
- Tipo fixo por perfil: `band`, `venue` ou `producer`
- Tipo determina capacidades disponíveis na plataforma

### Matriz de Permissões

| Ação | Banda | Venue | Produtor | Admin |
|---|---|---|---|---|
| Criar conexão com outras bandas | ✓ | — | — | — |
| Iniciar proposta de evento | ✓ | ✓ | ✓ | — |
| Aprovar/rejeitar proposta | — | ✓ | — | — |
| Aparecer no mapa | ✓ | ✓ | ✓ | — |
| Criar mini landing page | ✓ | ✓ | ✓ | — |
| Chat com outros usuários | ✓ | ✓ | ✓ | — |
| Moderar usuários/perfis | — | — | — | ✓ |

### Conformidade (LGPD)

- Consentimento explícito e política de privacidade no cadastro
- Controle de visibilidade do pin no mapa (usuário pode optar por não aparecer)
- Mecanismo de exclusão permanente de conta e dados
- Sistema de denúncias para perfis e mensagens de chat

## Requisitos Funcionais

### Gestão de Usuários e Autenticação

- **FR01:** Visitante pode criar conta com e-mail e senha
- **FR02:** Visitante pode criar conta via OAuth (Google ou Facebook)
- **FR03:** Usuário pode fazer login com e-mail/senha ou OAuth
- **FR04:** Usuário pode recuperar senha por e-mail
- **FR05:** Usuário pode excluir conta e dados permanentemente (LGPD)
- **FR06:** Usuário aceita termos de uso e política de privacidade no cadastro

### Perfis e Identidade

- **FR07:** Usuário cria perfil com tipo fixo: banda, casa de shows ou produtor
- **FR08:** Usuário edita informações do perfil (nome, bio, gênero musical, cidade, membros, fotos)
- **FR09:** Usuário controla visibilidade do pin no mapa (público ou oculto)
- **FR10:** Usuário visualiza perfil público de outros usuários

### Mapa e Descoberta Geográfica

- **FR11:** Usuário visualiza mapa interativo com pins de bandas, venues e produtores por cidade
- **FR12:** Usuário clica em pin para visualizar perfil resumido da entidade
- **FR13:** Usuário filtra pins por tipo de entidade (banda, venue, produtor)
- **FR14:** Usuário navega pelo mapa livremente (zoom, pan, busca por cidade)

### Sistema de Conexões

- **FR15:** Banda envia convite de conexão para outra banda
- **FR16:** Banda aceita ou recusa convite de conexão
- **FR17:** Banda visualiza suas conexões ativas
- **FR18:** Banda desfaz uma conexão existente

### Workflow de Propostas de Eventos

- **FR19:** Banda (com conexão ativa) cria e envia proposta de evento para venue
- **FR20:** Venue cria proposta de evento selecionando bandas diretamente
- **FR21:** Produtor cria proposta de evento selecionando venue e bandas
- **FR22:** Venue aceita ou rejeita proposta de evento recebida
- **FR23:** Usuário visualiza histórico de propostas enviadas e recebidas
- **FR24:** Usuário cancela proposta antes da decisão final

### Comunicação

- **FR25:** Usuário inicia conversa de chat com outro usuário
- **FR26:** Usuário envia e recebe mensagens em tempo real
- **FR27:** Usuário visualiza histórico de conversas
- **FR28:** Usuário recebe notificação in-app ao receber nova mensagem
- **FR29:** Usuário recebe notificação in-app quando proposta é enviada, aceita ou rejeitada
- **FR30:** Usuário denuncia mensagem de chat

### Mini Landing Pages

- **FR31:** Usuário cria mini landing page associada ao perfil
- **FR32:** Usuário edita blocos de conteúdo da landing page (texto, imagens, links)
- **FR33:** Landing page é acessível por URL pública
- **FR34:** Visitante visualiza landing page sem estar autenticado

### Administração e Moderação

- **FR35:** Admin visualiza métricas da plataforma (cadastros, propostas, shows fechados)
- **FR36:** Admin modera e remove perfis que violam termos de uso
- **FR37:** Admin visualiza e resolve denúncias de usuários
- **FR38:** Admin bloqueia ou desbloqueia usuários

## Requisitos Não-Funcionais

### Performance

- Carregamento inicial do mapa: < 2 segundos em conexão padrão
- Atualização de pins: < 1 segundo
- Entrega de mensagens de chat: < 500ms
- Respostas da API para ações do usuário: < 1 segundo

### Segurança

- Todas as comunicações via HTTPS (TLS 1.2+)
- Mensagens de chat criptografadas em trânsito e em repouso
- Senhas armazenadas com bcrypt
- Tokens OAuth sem exposição no cliente
- Exclusão permanente de dados pessoais disponível (LGPD)

### Confiabilidade

- Disponibilidade: 99.5% uptime (< 4 horas de downtime/mês)
- Falhas no chat isoladas do restante da plataforma
- Propostas e conexões persistidas com garantia de durabilidade

### Escalabilidade

MVP dimensionado para lançamento em Jundiaí. Requisitos de escala para expansão nacional definidos na Fase 2.
