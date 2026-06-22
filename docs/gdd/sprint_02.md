# GDD — Sprint 02: Pathfinding A* + Obstáculos + Destaque de Tile

## Visão Geral

Sprint 2 expande a interação do jogador com o grid. O herói não mais
teletransporta: ao tocar uma célula válida, um caminho A* é calculado, os tiles
do percurso são destacados, e o herói anima passo a passo até o destino.
Células bloqueadas (definidas em JSON) impedem a passagem. Ao tocar no próprio
herói, tiles alcançáveis dentro de seu alcance são destacados em verde.

## O que o jogador vê e faz

**Mudanças visuais (além do Sprint 1):**
- Tiles bloqueados: losango vermelho escuro (mesma cor, agora visíveis no grid)
- Tiles alcançáveis: losango verde semitransparente (0.0, 1.0, 0.0, 0.3)
- Tiles do path: losango laranja semitransparente (1.0, 0.6, 0.0, 0.4)
- Tile destino: losango amarelo (mesmo do Sprint 1)
- Herói move-se suavemente tile a tile, sem teletransporte

**Ações do jogador:**
1. **Tocar uma célula vazia e desbloqueada** → calcula path A* do herói até lá
   → destaca path em laranja → herói anima caminhando tile a tile
2. **Tocar o próprio herói** → destaca tiles alcançáveis (BFS com range do JSON)
   em verde
3. **Tocar célula bloqueada ou fora do grid** → nada acontece
4. **Tocar célula inalcançável (sem path)** → nada acontece
5. **Pinçar** → zoom da câmera (inalterado)

**Estados do grid:**
- `0` (FREE) — losango cinza claro
- `1` (BLOCKED) — losango vermelho escuro
- Reachable tiles — verde translúcido (sobreposto ao estado base)
- Path tiles — laranja translúcido (sobreposto ao estado base)
- Tile destino — amarelo translúcido (sobreposto ao path)

## Especificação Técnica

### Grid (GridSystem) — métodos novos/alterados

| Método | Assinatura | Descrição |
|--------|-----------|-----------|
| `get_cell` | `(pos: Vector2i) -> int` | Retorna 0 (FREE) ou 1 (BLOCKED) |
| `set_cell_occupied` | `(pos: Vector2i, blocked: bool)` | Marca/desmarca célula como bloqueada |
| `get_neighbors` | `(pos: Vector2i) -> Array[Vector2i]` | 4-dir manhattan, respeita bounds |
| `find_path` | `(from: Vector2i, to: Vector2i) -> Array[Vector2i]` | A* com heurística manhattan, retorna array vazio se sem path |
| `get_reachable_tiles` | `(pos: Vector2i, range: int) -> Array[Vector2i]` | BFS de pos com limite range |
| `highlight_cells` | `(cells: Array[Vector2i], color: Color)` | Marca múltiplas células para _draw() |
| `clear_highlights` | `() -> void` | Limpa todos os highlights |

**Alteração interna:** `highlighted_cell: Vector2i` (único) →
`_highlighted_cells: Array[Vector2i]` + `_highlight_colors: Dictionary` — cada
célula destacada pode ter sua própria cor.

**A* — Algoritmo:**
- 4 direções (cima, baixo, esquerda, direita no grid, não isométrico)
- Heurística: manhattan (`abs(to.x - from.x) + abs(to.y - from.y)`)
- Célula bloqueada (`grid_data[x][y] == 1`) não entra na open set
- Retorna array de `Vector2i` incluindo `from` e `to`
- Array vazio se destino bloqueado ou sem caminho
- Prior queue via array simples (grid 8×8, performance não crítica)

**BFS — Reachable tiles:**
- Usa fila, parte de `pos`, explora 4-dir
- Para cada vizinho: se dentro do grid, desbloqueado, e distância ≤ range
- Ignora custo de terreno (todos os tiles livres custam 1)
- Retorna `Array[Vector2i]` sem incluir a posição inicial

### Hero — métodos novos

| Propriedade/Método | Descrição |
|-------------------|-----------|
| `hero_move_range: int` | Alcance de movimento (carregado do JSON, padrão 3) |
| `move_along_path(path: Array[Vector2i])` | Anima herói tile a tile via Tween |
| `is_moving: bool` | Flag para bloquear input durante animação |

**Animação (`move_along_path`):**
- Recebe path completo (inclui posição atual e destino)
- Itera do índice 1 em diante (pula posição atual)
- Para cada passo: cria Tween que interpola `position` do tile atual ao próximo
- Duração por passo: 0.15s
- `is_moving = true` no início, `is_moving = false` no final
- Input bloqueado durante movimento (CombatScene ignora taps se hero.is_moving)

### CombatScene — alterações no fluxo

```
Touch (input) → TouchController → signal screen_tapped(screen_pos)
                                      ↓
                              CombatScene._on_screen_tapped()
                                      ↓
                            canvas_transform.affine_inverse()
                                      ↓
                            world_pos → grid_system.world_to_grid()
                                      ↓
                            grid_pos dentro dos bounds?
                              ├── Sim → hero.is_moving?
                              │           ├── Sim → no-op (ignora input)
                              │           └── Não → grid_pos == hero.grid_position?
                              │                       ├── Sim → destaca tiles alcançáveis
                              │                       └── Não → calcula path A*
                              │                               ├── path não vazio?
                              │                               │   ├── Sim → clear_highlights()
                              │                               │   │       → highlight_cells(path, orange)
                              │                               │   │       → hero.move_along_path(path)
                              │                               │   └── Não → no-op
                              └── Não → no-op
```

**Pós-movimento:** Ao final da animação, `clear_highlights()` é chamado para
remover path laranja.

### Data — JSON de cenário

**`data/combat/scenario_01.json`:**
```json
{
  "grid_size": [8, 8],
  "blocked_cells": [[2, 2], [2, 3], [3, 2]],
  "hero_start": [0, 0],
  "hero_move_range": 3
}
```

**Carregamento no GridSystem:**
- `setup()` recebe caminho JSON opcional
- Se fornecido: parseia JSON, seta grid_size, marca blocked_cells
- Se não: usa default 8×8, sem bloqueios

**Método auxiliar:** `load_scenario(path: String) -> void` — carrega JSON,
chama `setup()` com dados.

### Highlight — múltiplas células

**`_draw()` alterado:**
- Itera grid_data normalmente para cor base (cinza/vermelho)
- Se célula estiver em `_highlighted_cells`: desenha overlay com cor específica
- Ordem: base → reachable → path → destination (último sobrepõe)

**Cores:**
| Tipo | Cor |
|------|-----|
| Reachable tile | `Color(0.0, 1.0, 0.0, 0.3)` |
| Path tile | `Color(1.0, 0.6, 0.0, 0.4)` |
| Destination tile | `Color(1.0, 1.0, 0.0, 0.5)` |

### Árvore da Cena (CombatScene) — inalterada

```
root (Node2D) → combat_scene.gd (CombatScene)
├── GridSystem (Node2D) → grid_system.gd (GridSystem)
├── Hero (Node2D) → hero.gd (Hero)
├── Camera (Camera2D)
│   ├── position = (0, 80)
│   └── zoom = (2, 2)
└── TouchController (Node) → touch_controller.gd (TouchController)
```

## Critérios de Aceitação

1. **Obstáculos visíveis:** tiles definidos como bloqueados no JSON aparecem
   em vermelho escuro
2. **Path A* calculado:** ao tocar célula vazia e desbloqueada, tiles do caminho
   são destacados em laranja
3. **Movimento animado:** herói caminha tile a tile (0.15s por passo) até o
   destino, sem teletransporte
4. **Bloqueio de input:** durante animação, toques são ignorados
5. **Alcance visível:** ao tocar o herói, tiles alcançáveis dentro do range
   são destacados em verde
6. **Tile bloqueado impede path:** A* desvia de bloqueios ou retorna vazio sem
   crash
7. **Célula inalcançável:** sem path, sem animação, sem highlight
8. **Testes gdUnit4 passam:** unit + property + contract + smoke
9. **APK exportável**

## Fora do Escopo

- Inimigos / unidades múltiplas (Sprint 3)
- Sistema de turnos (Sprint 3)
- HUD / barra de status (Sprint 5+)
- Custo de terreno variável (todos livres = custo 1)
- Pathfinding com 8-dir (apenas 4-dir manhattan)
- A* com weighted tiles / elevation
- Animações de sprite (usamos _draw() placeholders)
- Música e SFX
