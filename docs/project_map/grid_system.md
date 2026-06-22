# GridSystem

## Descrição
Sistema de grid isométrico para movimentação de unidades no mapa tático.

## Componentes
- GridSystem: Sistema de grid isométrico (8×8 padrão, tiles 32×16), conversão world↔grid, pathfinding A* (4-dir manhattan), BFS de tiles alcançáveis, suporte a células bloqueadas via JSON
- Hero: Entidade controlável com teleporte (Sprint 1) e movimento animado via Tween (Sprint 2)
- TouchController: Input touch, emite `screen_tapped(screen_pos: Vector2)`
- Camera2D: Câmera fixa centralizada no grid, zoom por pinch 0.5×–4×

## Scripts
- `src/systems/grid_system.gd`: GridSystem (class_name), grid 8×8 data-driven via setup(), conversão isométrica, A* find_path(), BFS get_reachable_tiles(), highlight múltiplo
- `src/entities/hero.gd`: Hero (class_name), teleport_to com grid_system injetado, move_along_path() com Tween
- `src/input/touch_controller.gd`: TouchController (class_name), sinal screen_tapped, pinch zoom
- `src/scenes/combat_scene.gd`: CombatScene — wiring (mediador: screen→world→grid→path→move)

## Decisões de Design
- D8: Movimento animado via Tween (0.15s por tile), não teleporte
- D9: Path A* destacado em laranja antes do movimento
- D10: BFS de tiles alcançáveis destacado em verde ao tocar no herói
- D11: Obstáculos carregados de `data/combat/scenario_01.json`

## Cenas
- `res://src/scenes/combat_scene.tscn`: Cena principal (GridSystem + Hero + Camera + TouchController)
