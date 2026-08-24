extends GutTest
# Input real: long-press 0.6s -> info da unidade; EndTurn do HUD -> turno avança
# Assert no CONSUMIDOR (Label3D de info criado na cena / TurnManager avança)


func test_long_press_mostra_info_unidade() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	assert_not_null(unit)
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	assert_not_null(cam)
	var pos: Vector2 = cam.unproject_position(unit.position + Vector3(0, 0.4, 0))
	# ACT — press e segura > 0.6s via evento touch real no handler da cena
	var press := InputEventScreenTouch.new()
	press.index = 3
	press.pressed = true
	press.position = pos
	arena._unhandled_input(press)
	await get_tree().create_timer(0.75).timeout
	# ASSERT no consumidor: Label3D de info criado com nome/HP da unidade
	var found: Label3D = null
	for c in arena.get_children():
		if c is Label3D and str((c as Label3D).text).begins_with(unit.display_name):
			found = c
			break
	assert_not_null(found, "long-press deve criar Label3D info da unidade")
	if found:
		assert_true(str(found.text).contains("HP:"), "info deve conter HP (consumidor visual)")
	# release encerra estado do long-press
	var release := InputEventScreenTouch.new()
	release.index = 3
	release.pressed = false
	release.position = pos
	arena._unhandled_input(release)
	await get_tree().process_frame


func test_hud_end_turn_avanca_turno() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	var hud: Control = arena.get_node_or_null("CanvasLayer/TacticalHUD") as Control
	assert_not_null(turn)
	assert_not_null(hud)
	var before: Unit = turn.get_current_unit()
	assert_not_null(before)
	# ACT — botão real Passar Turno do HUD (boundary UI -> sinal end_turn_pressed)
	var end_btn: Button = hud.get_node_or_null("HBox/EndTurn") as Button
	assert_not_null(end_btn, "botão EndTurn deve existir")
	end_btn.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	# ASSERT no consumidor downstream (TurnManager)
	var after: Unit = turn.get_current_unit()
	assert_not_same(after, before, "EndTurn do HUD deve avançar para próxima unidade (RR)")
