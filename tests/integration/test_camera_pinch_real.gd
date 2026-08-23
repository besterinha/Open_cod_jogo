extends GutTest
# Teste com capacidade de falhar — percorre caminho real do pinch (2 toques + drag), não injeção direta de MagnifyGesture


func _make_rig() -> CameraRig:
	var rig := CameraRig.new()
	rig.grid_limit = Vector2i(8, 8)
	rig.pan_speed = 0.015
	rig.min_size = 6.0
	rig.max_size = 16.0
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	cam.transform = Transform3D(
		Basis.from_euler(Vector3(deg_to_rad(-45), deg_to_rad(45), 0)), Vector3.ZERO
	)
	rig.camera = cam
	rig.add_child(cam)
	add_child_autofree(rig)
	await get_tree().process_frame
	return rig


func test_pinch_caminho_real_falha_se_sem_fallback() -> void:
	var rig := await _make_rig()
	var cam: Camera3D = rig.camera
	var before: float = cam.size
	# simula caminho real: 2 toques + drag afastando (deveria dar zoom in via fallback)
	var t0_press := InputEventScreenTouch.new()
	t0_press.index = 0
	t0_press.position = Vector2(100, 100)
	t0_press.pressed = true
	var t1_press := InputEventScreenTouch.new()
	t1_press.index = 1
	t1_press.position = Vector2(200, 100)
	t1_press.pressed = true
	rig._unhandled_input(t0_press)
	rig._unhandled_input(t1_press)
	await get_tree().process_frame
	# drag afastando: p0 vai para 50,100 e p1 para 250,100 => distância 100 -> 200, factor 2.0 => size 5 (clamp 6)
	var drag0 := InputEventScreenDrag.new()
	drag0.index = 0
	drag0.position = Vector2(50, 100)
	drag0.relative = Vector2(-50, 0)
	var drag1 := InputEventScreenDrag.new()
	drag1.index = 1
	drag1.position = Vector2(250, 100)
	drag1.relative = Vector2(50, 0)
	rig._unhandled_input(drag0)
	rig._unhandled_input(drag1)
	await get_tree().process_frame
	# com fallback, deve ter dado zoom in (size diminui)
	assert_ne(cam.size, before, "pinch caminho real deve mudar size (fallback manual)")
	assert_true(cam.size < before or cam.size == rig.min_size, "pinch afastando deve diminuir size")


func test_magnify_gesture_ainda_funciona() -> void:
	var rig := await _make_rig()
	var cam: Camera3D = rig.camera
	var before: float = cam.size
	var mag := InputEventMagnifyGesture.new()
	mag.factor = 2.0
	rig._unhandled_input(mag)
	await get_tree().process_frame
	assert_ne(
		cam.size, before, "MagnifyGesture direto ainda deve funcionar como fallback do sistema"
	)
