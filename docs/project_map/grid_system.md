# GridSystem

## Descrição
Sistema de grid isométrico para movimentação de unidades no mapa tático.

## Componentes
- GridSystem: Sistema de grid isométrico (10×10, tiles 32×16), conversão world↔grid
- Hero: Entidade controlável com teleporte via clique
- TouchController: Input touch/mouse, emite `world_tapped`
- Camera2D: Câmera centralizada no grid

## Scripts
- `src/systems/grid_system.gd`: GridSystem (class_name), grid 10×10, conversão isométrica
- `src/entities/hero.gd`: Hero (class_name), teleport_to com grid_to_world
- `src/input/touch_controller.gd`: TouchController (class_name), sinal world_tapped

## Cenas
- `res://src/scenes/combat_scene.tscn`: Cena de combate (GridSystem + Hero + Camera + TouchController)
- `res://src/scenes/main_scene.tscn`: Cena principal (placeholder)
