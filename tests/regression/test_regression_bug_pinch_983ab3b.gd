extends GutTest
# Regression para 983ab3b: pinch fallback + enable_pan_and_scale_gestures
# Se voltar a quebrar, este teste falha (C8).

func test_regression_pinch_gestures_habilitado() -> void:
	assert_true(ProjectSettings.get_setting("input_devices/pointing/android/enable_pan_and_scale_gestures"),
		"enable_pan_and_scale_gestures deve estar true (983ab3b)")

func test_regression_pinch_fallback_existe() -> void:
	var rig := CameraRig.new()
	assert_true(rig.has_method("_handle_pinch_fallback"), "CameraRig deve ter fallback pinch distance")
	assert_true(rig.has_method("_get_touch_count"), "CameraRig deve bloquear pan com 2 dedos")
