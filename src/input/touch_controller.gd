extends Node
class_name TouchController

signal world_tapped(world_pos: Vector2)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_tap_detected(event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_tap_detected(event.position)


func _tap_detected(screen_pos: Vector2) -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var world_pos: Vector2 = viewport.canvas_transform.affine_inverse() * screen_pos
	world_tapped.emit(world_pos)
