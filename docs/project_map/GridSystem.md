# GridSystem

## Descrição
Sistema de grid isométrico para movimentação de unidades no mapa tático.

## Componentes
- Grid: Representa o mapa isométrico (10x10, tiles isométricos 64x32)
- Pathfinding: Algoritmo A* com heurística Manhattan (4 direções)
- GridTile: Resource que representa cada tile (walkable, occupied, position)
- Unidade: Placeholder visual para representar a unidade controlável
- Câmera: Controla a visão sobre o grid (setas/WASD + zoom scroll)

## Cenas
- `src/grid/grid_test.tscn`: Cena de teste para o GridSystem (Node > Node2D > GridSystem + Unit)

## Scripts
- `GridSystem.gd`: Sistema principal do grid (GridTile[], conversão iso, walkable/occupied)
- `GridTile.gd`: Resource class para tiles individuais
- `Pathfinder.gd`: A* com _get_neighbors (4-dir), _heuristic (Manhattan), suporte a obstáculos
- `Unit.gd`: Unidade com move_to usando Pathfinder, conversão isométrica grid<->screen
- `camera_controller.gd`: Controle por teclado (setas/WASD) + zoom (scroll)

## Sinais
- `unit_moved` (Unit.gd): Disparado quando uma unidade é movida
- `path_completed` (Unit.gd): Disparado quando o path é concluído

## Estado (StateSystem)
- `grid_initialized`: bool
- `camera_position_x`: float
- `camera_position_y`: float

## Dependências
- StateSystem (para variáveis de estado)
