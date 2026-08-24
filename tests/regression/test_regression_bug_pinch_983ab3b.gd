extends GutTest
# Regression para 983ab3b: pinch fallback + enable_pan_and_scale_gestures
# Se voltar a quebrar, este teste falha (C8). Comportamento real, não reflexão.


func test_regression_pinch_gestures_habilitado() -> void:
	assert_true(
		ProjectSettings.get_setting("input_devices/pointing/android/enable_pan_and_scale_gestures"),
		"enable_pan_and_scale_gestures deve estar true (983ab3b)"
	)


func test_regression_pinch_fallback_muda_zoom() -> void:
	var rig := CameraRig.new()
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	rig.add_child(cam)
	add_child_autofree(rig)
	await get_tree().process_frame
	assert_eq(cam.size, 10.0)
	# dois dedos na tela
	for i in 2:
		var t := InputEventScreenTouch.new()
		t.index = i
		t.pressed = true
		t.position = Vector2(100 + i * 100, 200)
		rig._unhandled_input(t)
	# dedos se afastam (zoom in => size diminui): dist 100 -> 220, fator 2.2
	var d0 := InputEventScreenDrag.new()
	d0.index = 0
	d0.position = Vector2(40, 200)
	rig._unhandled_input(d0)
	var d1 := InputEventScreenDrag.new()
	d1.index = 1
	d1.position = Vector2(260, 200)
	rig._unhandled_input(d1)
	# ASSERT no consumidor real (Camera3D.size), com clamp respeitado
	assert_lt(cam.size, 10.0, "pinch fallback deve diminuir size (zoom in) — consumidor Camera3D")
	assert_true(
		cam.size >= rig.min_size and cam.size <= rig.max_size, "size deve respeitar clamp min/max"
	)
