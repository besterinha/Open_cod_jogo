extends Node3D
# CameraRig touch — drag pan + pinch zoom para 2.5D isométrico ortogonal.
# Uso: coloque Camera3D como filho deste Node3D. Rig move no plano XZ, câmera mantém offset.

@export var camera: Camera3D
@export var pan_speed: float = 0.02
@export var min_size: float = 6.0
@export var max_size: float = 16.0
@export var grid_limit: Vector2i = Vector2i(8, 8)

var _dragging: bool = false
var _last_drag_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	if camera == null:
		camera = get_node_or_null("Camera3D") as Camera3D
		if camera == null:
			for child in get_children():
				if child is Camera3D:
					camera = child as Camera3D
					break

func _unhandled_input(event: InputEvent) -> void:
	# Drag com 1 dedo (ou mouse com botão esquerdo) — pan
	if event is InputEventScreenDrag:
		# só pan se não for pinch (magnify) — Godot envia drag mesmo durante pinch, mas magnify vem separado
		if event.index == 0:
			position.x -= event.relative.x * pan_speed
			position.z -= event.relative.y * pan_speed # isométrico: drag Y move Z também
			_clamp_position()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_dragging = true
			_last_drag_pos = event.position
		else:
			_dragging = false
	elif event is InputEventMagnifyGesture:
		if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
			camera.size = clamp(camera.size / event.factor, min_size, max_size)
			get_viewport().set_input_as_handled()
	# Mouse drag para debug PC
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		if Input.is_key_pressed(KEY_CTRL) or _dragging:
			position.x -= event.relative.x * pan_speed
			position.z -= event.relative.y * pan_speed
			_clamp_position()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				camera.size = clamp(camera.size - 0.5, min_size, max_size)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if camera and camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
				camera.size = clamp(camera.size + 0.5, min_size, max_size)

func _clamp_position() -> void:
	# limita rig para não sair muito do grid 8x8 (world 0-8)
	var limit: float = 4.0
	position.x = clamp(position.x, -limit, float(grid_limit.x) + limit)
	position.z = clamp(position.z, -limit, float(grid_limit.y) + limit)
