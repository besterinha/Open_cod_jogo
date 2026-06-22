extends GdUnitTestSuite


func test_signal_screen_tapped_exists() -> void:
	var controller := TouchController.new()
	assert_bool(controller.has_signal("screen_tapped")).is_true()
	controller.queue_free()


func test_signal_has_vector2_parameter() -> void:
	var controller := TouchController.new()
	var signal_info: Dictionary = {
		"args": [],
		"flags": 0,
		"name": "screen_tapped",
	}
	var found := false
	for sig in controller.get_signal_list():
		if sig["name"] == "screen_tapped":
			found = true
			assert_int(sig["args"].size()).is_equal(1)
			assert_int(sig["args"][0]["type"]).is_equal(TYPE_VECTOR2)
			break
	assert_bool(found).is_true()
	controller.queue_free()


func test_screen_tapped_emitted_on_single_touch_release() -> void:
	var controller := TouchController.new()
	add_child(controller)
	var emitted := false
	var received_pos := Vector2.ZERO
	controller.screen_tapped.connect(
		func(pos: Vector2) -> void:
			emitted = true
			received_pos = pos
	)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	press.position = Vector2(100, 200)
	controller._unhandled_input(press)
	assert_bool(emitted).is_false()
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.pressed = false
	release.position = Vector2(100, 200)
	controller._unhandled_input(release)
	assert_bool(emitted).is_true()
	assert_float(received_pos.x).is_equal(100.0)
	assert_float(received_pos.y).is_equal(200.0)
	controller.queue_free()


func test_screen_tapped_not_emitted_during_pinch() -> void:
	var controller := TouchController.new()
	add_child(controller)
	var emitted := false
	controller.screen_tapped.connect(
		func(_pos: Vector2) -> void:
			emitted = true
	)
	var press1 := InputEventScreenTouch.new()
	press1.index = 0
	press1.pressed = true
	press1.position = Vector2(100, 100)
	controller._unhandled_input(press1)
	var press2 := InputEventScreenTouch.new()
	press2.index = 1
	press2.pressed = true
	press2.position = Vector2(200, 200)
	controller._unhandled_input(press2)
	var release1 := InputEventScreenTouch.new()
	release1.index = 0
	release1.pressed = false
	release1.position = Vector2(100, 100)
	controller._unhandled_input(release1)
	var release2 := InputEventScreenTouch.new()
	release2.index = 1
	release2.pressed = false
	release2.position = Vector2(200, 200)
	controller._unhandled_input(release2)
	assert_bool(emitted).is_false()
	controller.queue_free()


func test_screen_tapped_not_emitted_when_second_finger_cancels() -> void:
	var controller := TouchController.new()
	add_child(controller)
	var emitted := false
	controller.screen_tapped.connect(
		func(_pos: Vector2) -> void:
			emitted = true
	)
	var press1 := InputEventScreenTouch.new()
	press1.index = 0
	press1.pressed = true
	press1.position = Vector2(50, 50)
	controller._unhandled_input(press1)
	var press2 := InputEventScreenTouch.new()
	press2.index = 1
	press2.pressed = true
	press2.position = Vector2(150, 150)
	controller._unhandled_input(press2)
	var release1 := InputEventScreenTouch.new()
	release1.index = 0
	release1.pressed = false
	release1.position = Vector2(50, 50)
	controller._unhandled_input(release1)
	assert_bool(emitted).is_false()
	controller.queue_free()
