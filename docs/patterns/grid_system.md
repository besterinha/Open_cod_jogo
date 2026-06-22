# Pattern: Grid System

## Descrição
Sistema de grid isométrico para movimentação tática. TILESIZE 32x16.

## Regras de Implementação
- Grid com coordenadas isométricas
- Conversão entre coordenadas de tela, mundo e grid
- Algoritmo A* para pathfinding (Sprint 2)
- Cada célula pode estar livre (0) ou bloqueada (1)
- Unidades ocupam uma célula por vez

## Interface Pública
- `setup(size: Vector2i)` — inicializa grid com tamanho data-driven
- `world_to_grid(world_pos: Vector2) -> Vector2i`
- `grid_to_world(grid_pos: Vector2i) -> Vector2`
- `is_within_bounds(pos: Vector2i) -> bool`
- `highlight_cell(pos: Vector2i)` — marca célula para _draw()
- `get_cell(pos: Vector2i) -> int` — retorna 0 (livre) ou 1 (bloqueado)
- `find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]` (Sprint 2)
- `set_cell_occupied(pos: Vector2i, occupied: bool)` (Sprint 2)

## Sinais
- TouchController emite `screen_tapped(screen_pos: Vector2)` — coordenadas cruas da tela
- CombatScene (mediador) converte screen → world → grid → teleporta herói

## Decisão de Câmera (Sprint 1)
- Câmera fixa centralizada no grid
- Posicionada em (0, 80), zoom inicial (2, 2)
- Zoom por pinch 0.5×–4× (via TouchController)
- Sem pan, sem follow — reavaliar no Sprint 2

## Placeholders (Sprint 1, via _draw())
- Tiles livres: losangos cinza-claro com borda cinza-escuro
- Tiles bloqueados: losangos vermelho-escuro
- Highlight: losango amarelo semitransparente
- Herói: círculo azul (raio 10px)
- Inimigos: a definir no Sprint 3
