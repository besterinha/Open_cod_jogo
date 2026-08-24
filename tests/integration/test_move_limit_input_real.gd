extends GutTest
# Input real: 1 movimento por turno (GDD "Mover + Ação") — 2º tap-move ignorado no
# consumidor Board; próximo turno reseta moves_left e nova unidade anda


func test_segundo_move_mesmo_turno_ignorado() -> void:
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
	# ARRANGE: espera animação do turno inicial não existir; garante destino livre
	var d1: Vector2i = unit.cell + Vector2i(1, 0)
	if not board.is_walkable(d1):
		return
	# ACT 1 — primeiro move (aceito, consome moves_left)
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(d1)))
	await get_tree().create_timer(0.70 + 0.25).timeout
	assert_eq(board.get_unit_at(d1), unit, "1º move deve ocupar destino no consumidor")
	# ACT 2 — segundo move no mesmo turno (deve ser ignorado mesmo após animação)
	var d2: Vector2i = d1 + Vector2i(0, 1)
	if board.is_walkable(d2):
		arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(d2)))
		await get_tree().process_frame
		await get_tree().create_timer(0.1).timeout
		assert_null(board.get_unit_at(d2), "consumidor Board: 2º move no mesmo turno ignorado")
		assert_eq(unit.cell, d1, "cell permanece no 1º destino")


func test_moves_resetam_no_proximo_turno() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	var hud: Control = arena.get_node_or_null("CanvasLayer/TacticalHUD") as Control
	var hero1: Unit = turn.get_current_unit()
	if hero1 == null or hero1.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				hero1 = u
				break
	assert_not_null(hero1)
	# consome o movimento do Hero1
	var d1: Vector2i = hero1.cell + Vector2i(1, 0)
	if not board.is_walkable(d1):
		return
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(d1)))
	await get_tree().create_timer(0.70 + 0.25).timeout
	# passa a vez até chegar em outra unidade team 0 (Hero2) via botão real HUD
	var end_btn: Button = hud.get_node_or_null("HBox/EndTurn") as Button
	end_btn.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	var hero2: Unit = turn.get_current_unit()
	assert_not_same(hero2, hero1, "turno avançou para próxima unidade")
	# ASSERT consumidor: nova unidade tem seu movimento disponível (reset por _on_turn_started)
	var d2: Vector2i = hero2.cell + Vector2i(0, 1)
	if board.is_walkable(d2) and hero2.team == 0:
		arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(d2)))
		await get_tree().process_frame
		await get_tree().create_timer(0.1).timeout
		assert_eq(board.get_unit_at(d2), hero2, "moves_left resetado: nova unidade consegue mover")
