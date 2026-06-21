extends Node2D
class_name CombatScene

@onready var grid_system: GridSystem = $GridSystem
@onready var hero: Hero = $Hero
@onready var touch_controller: TouchController = $TouchController


func _ready() -> void:
	hero.grid_system = grid_system
	touch_controller.world_tapped.connect(_on_world_tapped)


func _on_world_tapped(world_pos: Vector2) -> void:
	var grid_pos: Vector2i = grid_system.world_to_grid(world_pos)
	if grid_system.is_within_bounds(grid_pos):
		hero.teleport_to(grid_pos)
