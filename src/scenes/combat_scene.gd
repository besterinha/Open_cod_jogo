extends Node2D
class_name CombatScene

@onready var grid_system: GridSystem = $GridSystem
@onready var hero: Hero = $Hero
@onready var touch_controller: TouchController = $TouchController


func _ready() -> void:
	hero.grid_system = grid_system
	touch_controller.screen_tapped.connect(_on_screen_tapped)


func _on_screen_tapped(screen_pos: Vector2) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var world_pos: Vector2 = viewport.canvas_transform.affine_inverse() * screen_pos
	var grid_pos: Vector2i = grid_system.world_to_grid(world_pos)
	if grid_system.is_within_bounds(grid_pos):
		grid_system.highlight_cell(grid_pos)
		hero.teleport_to(grid_pos)
