# Pattern: Grid System

## Descrição
Sistema de grid isométrico para movimentação tática.

## Regras de Implementação
- Grid com coordenadas isométricas
- Conversão entre coordenadas de tela e grid
- Algoritmo A* para pathfinding (Sprint 2)
- Cada célula pode estar livre ou ocupada
- Unidades ocupam uma célula por vez

## Interface Pública
- `world_to_grid(world_pos: Vector2) -> Vector2i`
- `grid_to_world(grid_pos: Vector2i) -> Vector2`
- `is_within_bounds(pos: Vector2i) -> bool`

## Decisão de Câmera (Sprint 1)
- Câmera fixa centralizada no grid
- Posicionada no centro do grid isométrico
- Sem pan, sem follow — decisão mais simples para Sprint 1
- Reavaliar no Sprint 2 com pathfinding

## Placeholders
- Tiles: retângulos cinzas
- Unidades: círculos coloridos
- Células bloqueadas: retângulos vermelhos
