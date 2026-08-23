extends GutTest
# Integração: Board + CameraRig + Input (completo HUD+Combat+Board para câmera)

func test_camera_pan_1_dedo_move() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var rig: CameraRig = arena.get_node_or_null("CameraRig") as CameraRig
	assert_not_null(rig, "CameraRig deve existir")
	var before: Vector3 = rig.position
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(200, 200)
	drag.relative = Vector2(80, 0)
	rig._active_touches.clear()
	rig._active_touches[0] = Vector2(200, 200)
	rig._unhandled_input(drag)
	await get_tree().process_frame
	assert_ne(rig.position, before, "drag 1 dedo deve mover câmera")

func test_camera_pincha_zoom_muda_size() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	var rig: CameraRig = arena.get_node_or_null("CameraRig") as CameraRig
	assert_not_null(rig)
	var cam: Camera3D = rig.camera
	if cam == null:
		cam = rig.get_node_or_null("Camera3D") as Camera3D
	assert_not_null(cam)
	var before: float = cam.size
	var mag := InputEventMagnifyGesture.new()
	mag.factor = 2.0
	rig._unhandled_input(mag)
	await get_tree().process_frame
	assert_ne(cam.size, before, "pinch deve mudar size")
	assert_true(cam.size >= rig.min_size and cam.size <= rig.max_size)

func test_camera_2_dedos_nao_pan() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	var rig: CameraRig = arena.get_node_or_null("CameraRig") as CameraRig
	assert_not_null(rig)
	rig._active_touches.clear()
	rig._active_touches[0] = Vector2(100, 100)
	rig._active_touches[1] = Vector2(200, 200)
	var before: Vector3 = rig.position
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(150, 150)
	drag.relative = Vector2(50, 0)
	rig._unhandled_input(drag)
	await get_tree().process_frame
	assert_eq(rig.position, before, "com 2 dedos pan deve ser bloqueado")

func test_highlight_limpa_ao_trocar_turno() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	assert_not_null(board)
	# aguarda turno inicial criar highlights
	await get_tree().process_frame
	var highlights_before: int = get_tree().get_nodes_in_group("highlight").size()
	assert_true(highlights_before > 0, "deve ter highlights no turno inicial")
	# força limpar ao trocar turno
	if arena.has_method("_clear_highlights"):
		arena.call("_clear_highlights")
		await get_tree().process_frame
		var after: int = get_tree().get_nodes_in_group("highlight").size()
		assert_eq(after, 0, "clear deve remover highlights")
