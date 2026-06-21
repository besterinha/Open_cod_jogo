extends Node2D
class_name Hero

var grid_position: Vector2i = Vector2i.ZERO
var grid_system: GridSystem = null


func teleport_to(pos: Vector2i) -> void:
	grid_position = pos
	if grid_system != null:
		position = grid_system.grid_to_world(pos)
