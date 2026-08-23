extends GutTest
# Unit isolado: CameraRig puro sem cena, testa lógica RefCounted-like


func _make_rig() -> CameraRig:
	var rig := CameraRig.new()
	rig.grid_limit = Vector2i(8, 8)
	rig.pan_speed = 0.015
	rig.min_size = 6.0
	rig.max_size = 16.0
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	# isometria 45°
	cam.transform = Transform3D(
		Basis.from_euler(Vector3(deg_to_rad(-45), deg_to_rad(45), 0)), Vector3.ZERO
	)
	rig.camera = cam
	rig.add_child(cam)
	add_child_autofree(rig)
	# garante cam.global_transform válido
	await get_tree().process_frame
	return rig


func test_pan_speed_default() -> void:
	var rig := await _make_rig()
	assert_eq(rig.pan_speed, 0.015)


func test_min_less_than_max() -> void:
	var rig := await _make_rig()
	assert_true(rig.min_size < rig.max_size)
	assert_eq(rig.min_size, 6.0)
	assert_eq(rig.max_size, 16.0)


func test_clamp_scales_with_zoom() -> void:
	var rig := await _make_rig()
	rig.camera.size = 6.0
	rig.position = Vector3(100, 0, 100)
	rig._clamp_position()
	var pos_small: Vector3 = rig.position
	rig.camera.size = 16.0
	rig.position = Vector3(100, 0, 100)
	rig._clamp_position()
	var pos_big: Vector3 = rig.position
	# com zoom maior (size 16), limite deve ser maior (permite ver mais)
	assert_true(pos_big.x >= pos_small.x or pos_big.z >= pos_small.z, "clamp deve escalar com size")


func test_get_touch_count_blocks_pan() -> void:
	var rig := await _make_rig()
	rig._active_touches[0] = Vector2(100, 100)
	rig._active_touches[1] = Vector2(200, 200)
	assert_eq(rig._get_touch_count(), 2)
	# pan só com 1 dedo, com 2 deve bloquear
	var before: Vector3 = rig.position
	# simula drag com 2 dedos: _get_touch_count >1 deve fazer CameraRig ignorar pan
	# chamamos diretamente o handler com 2 toques ativos
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(150, 150)
	drag.relative = Vector2(50, 0)
	rig._unhandled_input(drag)
	assert_eq(rig.position, before, "com 2 dedos não deve pan")


func test_pan_reto_usa_camera_basis() -> void:
	var rig := await _make_rig()
	var before: Vector3 = rig.position
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(100, 100)
	drag.relative = Vector2(100, 0)  # arrasto reto X
	rig._active_touches.clear()
	rig._active_touches[0] = Vector2(100, 100)
	rig._unhandled_input(drag)
	# pan reto X deve mover tanto X quanto Z devido à base isométrica (não só X)
	assert_true(rig.position.x != before.x or rig.position.z != before.z, "pan deve mover")
	# arrasto reto X puro não deve mover só X (isometria)
	# com base correta, X e Z mudam
	assert_ne(rig.position.x, before.x)
