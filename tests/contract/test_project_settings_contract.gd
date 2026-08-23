extends GutTest
# Contrato: project.godot deve ter gestos Android habilitados para pinch funcionar (caminho real)


func test_pan_and_scale_gestures_habilitado() -> void:
	var val: Variant = ProjectSettings.get_setting(
		"input_devices/pointing/android/enable_pan_and_scale_gestures", null
	)
	assert_not_null(
		val,
		"ProjectSettings input_devices/pointing/android/enable_pan_and_scale_gestures deve existir"
	)
	assert_true(
		bool(val),
		"enable_pan_and_scale_gestures deve ser true para pinch funcionar no device (caminho real)"
	)


func test_emulate_touch_from_mouse_desabilitado() -> void:
	var val: Variant = ProjectSettings.get_setting(
		"input_devices/pointing/emulate_touch_from_mouse", null
	)
	# não obrigatório, mas se existir deve ser false para não poluir touch em PC
	if val != null:
		assert_false(
			bool(val), "emulate_touch_from_mouse deve ser false para não gerar touch fantasma no PC"
		)
