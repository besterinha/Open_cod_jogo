extends Node2D
class_name Hero

var grid_position: Vector2i = Vector2i.ZERO
var grid_system: GridSystem = null


func teleport_to(pos: Vector2i) -> void:
	grid_position = pos
	if grid_system != null:
		position = grid_system.grid_to_world(pos)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 10.0, Color(0.2, 0.4, 0.8))
	draw_circle(Vector2.ZERO, 10.0, Color(0.3, 0.5, 0.9), false, 1.5)
