# Story 2.3: Controle de Visibilidade no Mapa (LGPD)

Status: review

## Story

Como usuário autenticado,
quero controlar se meu perfil aparece no mapa público,
para que eu possa exercer meu direito de privacidade conforme a LGPD.

## Acceptance Criteria

1. **[OCULTAR_DO_MAPA]** `PATCH /api/v1/profiles/:id` com `{ map_visible: false }` e JWT válido do dono
   - `map_visible` atualizado para `false`
   - HTTP 200 com perfil atualizado (map_visible: false)

2. **[REAPARECER_NO_MAPA]** `PATCH /api/v1/profiles/:id` com `{ map_visible: true }` e JWT válido do dono
   - `map_visible` atualizado para `true`
   - HTTP 200 com perfil atualizado (map_visible: true)

3. **[OUTRO_USUARIO]** JWT de outro usuário tentando alterar map_visible
   - HTTP 403 (já coberto pelo `update` da story 2.2)

4. **[SEM_AUTENTICACAO]** Sem JWT válido
   - HTTP 401 (já coberto pelo `authenticate_user!`)

## Tasks / Subtasks

- [x] **Task 1: Adicionar `map_visible` ao `update_params`** (AC: #1, #2)
  - [x] Em `app/controllers/api/v1/profiles_controller.rb`, adicionar `:map_visible` ao `update_params`
  - [x] Nenhuma outra mudança necessária — a action `update` já existe e trata todos os casos

- [x] **Task 2: Escrever testes** (AC: #1, #2)
  - [x] Em `test/controllers/api/v1/profiles_controller_test.rb`:
    - PATCH com `{ map_visible: false }` → 200 + map_visible é false
    - PATCH com `{ map_visible: true }` após ocultar → 200 + map_visible é true

## Dev Notes

### O que já existe

- `ProfilesController#update` com autorização e serialização (story 2.2)
- `update_params` em `profiles_controller.rb`: `permit(:name, :city, :bio, :music_genre)` — apenas adicionar `:map_visible`
- `map_visible` já existe na tabela `profiles` com `default: true` e índice
- `ProfileSerializer` já serializa `map_visible`

### Implementação mínima

Apenas uma linha de mudança:

```ruby
def update_params
  params.permit(:name, :city, :bio, :music_genre, :map_visible)
end
```

### Nota sobre "deixar de aparecer no mapa"

O AC menciona que o perfil "deixa de aparecer nas respostas de GET /api/v1/map/pins". O **filtro** de `map_visible` será implementado no `MapController` na Story 2.5. Nesta story, apenas garantimos que o campo pode ser controlado pelo usuário. Os testes desta story não testam o endpoint de pins (escopo da 2.5).

### References

- [Source: _bmad-output/planning-artifacts/epics.md#Story 2.3]
- [Source: app/controllers/api/v1/profiles_controller.rb]

## Dev Agent Record

### Agent Model Used

claude-sonnet-4-6

### Debug Log References

### Completion Notes List

- ✅ `:map_visible` adicionado ao `update_params` — 1 linha de mudança
- ✅ 2 testes novos: ocultar (false) e reativar (true) — ambos verificam DB com `profile.reload`
- ✅ Suite completa: 71 testes, 0 erros, 1 falha pré-existente (CORS)

### File List

- `app/controllers/api/v1/profiles_controller.rb` (modificado — `:map_visible` em `update_params`)
- `test/controllers/api/v1/profiles_controller_test.rb` (modificado — 2 novos testes)
