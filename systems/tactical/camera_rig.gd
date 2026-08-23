class_name CameraRig
extends Node3D
# CameraRig touch — drag pan + pinch zoom para 2.5D isométrico ortogonal.
# Uso: coloque Camera3D como filho deste Node3D. Rig move no plano XZ, câmera mantém offset.

@export var camera: Camera3D
@export var pan_speed: float = 0.015
@export var min_size: float = 6.0
@export var max_size: float = 16.0
@export var grid_limit: Vector2i = Vector2i(8, 8)

var _dragging: bool = false
var _last_drag_pos: Vector2 = Vector2.ZERO
var _active_touches: Dictionary = {}  # index -> Vector2
var _pinch_start_dist: float = 0.0
var _pinch_start_size: float = 0.0


func _ready() -> void:
	if camera == null:
		camera = get_node_or_null("Camera3D") as Camera3D
		if camera == null:
			for child in get_children():
				if child is Camera3D:
					camera = child as Camera3D
					break


func _handle_pinch_fallback() -> void:
	if (
		_active_touches.size() != 2
		or camera == null
		or camera.projection != Camera3D.PROJECTION_ORTHOGONAL
	):
		return
	var keys: Array = _active_touches.keys()
	var p0: Vector2 = _active_touches[keys[0]]
	var p1: Vector2 = _active_touches[keys[1]]
	var cur_dist: float = p0.distance_to(p1)
	if _pinch_start_dist == 0.0:
		_pinch_start_dist = cur_dist
		_pinch_start_size = camera.size
		return
	if cur_dist == 0 or _pinch_start_dist == 0:
		return
	var factor: float = cur_dist / _pinch_start_dist
	# factor >1 = dedos afastando = zoom in (size diminui)
	camera.size = clamp(_pinch_start_size / factor, min_size, max_size)


func _unhandled_input(event: InputEvent) -> void:
	# Drag só com 1 dedo — pan reto (corrige diagonal isométrica)
	if event is InputEventScreenDrag:
		# atualiza posições dos toques ativos para fallback pinch
		if _active_touches.has(event.index):
			_active_touches[event.index] = event.position
		if _active_touches.size() == 2:
			_handle_pinch_fallback()
			get_viewport().set_input_as_handled()
			return
		# ignora drag do 2º dedo durante pinch (só 1 dedo pan)
		if event.index != 0:
			return
		# se houver 2+ dedos na tela, não pan (pinch)
		if _get_touch_count() > 1:
			return
		if camera == null:
			return
		# base da câmera para pan reto: right/forward no plano XZ
		var cam_basis: Basis = camera.global_transform.basis
		var r: Vector3 = Vector3(cam_basis.x.x, 0, cam_basis.x.z).normalized()
		var f: Vector3 = Vector3(-cam_basis.z.x, 0, -cam_basis.z.z).normalized()
		var factor: float = pan_speed * (camera.size / 10.0)
		position -= r * event.relative.x * factor
		position += f * event.relative.y * factor
		_clamp_position()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_active_touches[event.index] = event.position
			_dragging = true
			_last_drag_pos = event.position
			if _active_touches.size() == 2:
				# inicia pinch: registra distância inicial
				var keys: Array = _active_touches.keys()
				_pinch_start_dist = _active_touches[keys[0]].distance_to(_active_touches[keys[1]])
				_pinch_start_size = camera.size if camera else 10.0
		else:
			_active_touches.erase(event.index)
			_dragging = false
			if _active_touches.size() < 2:
				_pinch_start_dist = 0.0
		return
	elif event is InputEventMagnifyGesture:
		if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
			camera.size = clamp(camera.size / event.factor, min_size, max_size)
			get_viewport().set_input_as_handled()
	# Mouse drag para debug PC
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if Input.is_key_pressed(KEY_CTRL) or _dragging:
			if camera == null:
				return
			var cam_basis2: Basis = camera.global_transform.basis
			var r2: Vector3 = Vector3(cam_basis2.x.x, 0, cam_basis2.x.z).normalized()
			var f2: Vector3 = Vector3(-cam_basis2.z.x, 0, -cam_basis2.z.z).normalized()
			var factor2: float = pan_speed * (camera.size / 10.0)
			position -= r2 * event.relative.x * factor2
			position += f2 * event.relative.y * factor2
			_clamp_position()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				camera.size = clamp(camera.size - 0.5, min_size, max_size)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				camera.size = clamp(camera.size + 0.5, min_size, max_size)


func _get_touch_count() -> int:
	return _active_touches.size()


func _clamp_position() -> void:
	# limita rig para não sair muito do grid 8x8 (world 0-8), escala com zoom
	var limit: float = 4.0 * (camera.size / 10.0) if camera else 4.0
	position.x = clamp(position.x, -limit, float(grid_limit.x) + limit)
	position.z = clamp(position.z, -limit, float(grid_limit.y) + limit)
