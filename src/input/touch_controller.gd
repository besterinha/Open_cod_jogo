extends Node
class_name TouchController

signal screen_tapped(screen_pos: Vector2)

var _touch_points: Dictionary = {}
var _initial_distance: float = 0.0
var _is_pinching: bool = false
var _tap_candidate_pos: Vector2 = Vector2.ZERO
var _tap_candidate_active: bool = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_touch_points[event.index] = event.position
		if _touch_points.size() == 1:
			_tap_candidate_pos = event.position
			_tap_candidate_active = true
		elif _touch_points.size() == 2:
			_tap_candidate_active = false
			var points := _touch_points.values()
			_initial_distance = points[0].distance_to(points[1])
			_is_pinching = true
	else:
		_touch_points.erase(event.index)
		if _touch_points.size() < 2:
			_is_pinching = false
		if _tap_candidate_active and _touch_points.is_empty():
			screen_tapped.emit(_tap_candidate_pos)
			_tap_candidate_active = false


func _on_drag(event: InputEventScreenDrag) -> void:
	_touch_points[event.index] = event.position
	if _is_pinching and _touch_points.size() == 2:
		var points := _touch_points.values()
		var current_distance: float = points[0].distance_to(points[1])
		if _initial_distance > 0:
			var camera := get_viewport().get_camera_2d()
			if camera != null:
				var zoom_factor: float = _initial_distance / current_distance
				camera.zoom = (camera.zoom * zoom_factor).clamp(
					Vector2(0.5, 0.5), Vector2(4.0, 4.0)
				)
		_initial_distance = current_distance
