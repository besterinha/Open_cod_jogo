# Pattern: Grid System

## Descrição
Sistema de grid isométrico para movimentação tática.

## Regras de Implementação
- Grid com coordenadas isométricas
- Conversão entre coordenadas de tela e grid
- Algoritmo A* para pathfinding
- Cada célula pode estar livre ou ocupada
- Unidades ocupam uma célula por vez

## Interface Pública
- `get_cell(position: Vector2) -> Dictionary`
- `is_cell_free(position: Vector2) -> bool`
- `find_path(start: Vector2, end: Vector2) -> Array`
- `move_unit(unit_id: String, path: Array) -> void`

## Placeholders
- Tiles: retângulos cinzas
- Unidades: círculos coloridos
- Células bloqueadas: retângulos vermelhos
