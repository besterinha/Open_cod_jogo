extends GutTest
# Regression: multi-tap durante animação — sem aceleração, sem corte diagonal
# Bug device: cada tap criava outro Tween sobre position (stack) e partia do meio do caminho


func test_move_unit_rejeita_segundo_enquanto_anima() -> void:
	var board := TacticalBoard.new()
	board.grid_size = Vector2i(6, 6)
	board.grid = GridSystem.new(Vector2i(6, 6), 1.0)
	add_child_autofree(board)
	var movement := MovementSystem.new()
	movement.setup(board)
	add_child_autofree(movement)
	var hero := Unit.new()
	hero.display_name = "Hero"
	hero.cell = Vector2i(0, 0)
	hero.stats = UnitStats.new()
	hero.stats.values = {"hp": 10, "movement": 5}
	# add_unit já adiciona à árvore (filho do board) — não duplicar parent
	board.add_unit(hero)
	hero.position = board.grid.cell_to_world(hero.cell)
	var target1 := Vector2i(2, 0)
	assert_true(movement.move_unit(hero, target1), "1º move aceito")
	assert_true(movement.is_moving(hero), "is_moving true durante animação")
	var pos_mid: Vector3 = hero.position
	# 2º movimento imediato deve ser REJEITADO (lock anti-stack)
	var ok2: bool = movement.move_unit(hero, Vector2i(4, 0))
	assert_false(ok2, "move_unit durante animação deve retornar false")
	await get_tree().create_timer(0.70 * 2.0 + 0.3).timeout
	assert_false(movement.is_moving(hero), "após animação completa is_moving false")
	var end_world: Vector3 = board.grid.cell_to_world(target1)
	assert_lt(
		hero.position.distance_to(end_world),
		0.15,
		"posição final = 1º alvo (sem overshoot/diagonal)"
	)
	assert_eq(board.get_unit_at(target1), hero)
	assert_null(board.get_unit_at(Vector2i(4, 0)), "segundo alvo nunca ocupado")


func test_multi_tap_para_no_primeiro_destino_input_real() -> void:
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
	var t1: Vector2i = unit.cell + Vector2i(1, 0)
	var t2: Vector2i = unit.cell + Vector2i(2, 0)
	for t in [t1, t2]:
		if not board.is_walkable(t):
			return  # layout sem espaço livre para o cenário do teste
	watch_signals(board)
	# ACT — dois taps quase simultâneos em destinos diferentes (input real)
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(t1)))
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(t2)))
	await get_tree().process_frame
	# ASSERT consumidor: só o 1º destino é ocupado; 2º tap ignorado pelo lock
	assert_eq(board.get_unit_at(t1), unit, "board deve ver unit no 1º destino (occupancy imediata)")
	assert_null(board.get_unit_at(t2), "2º tap não deve ocupar segundo destino")
	await get_tree().create_timer(0.70 * 2.0 + 0.3).timeout
	var end_world: Vector3 = board.grid.cell_to_world(t1)
	assert_lt(unit.position.distance_to(end_world), 0.15, "sem aceleração/corte: para no 1º")
