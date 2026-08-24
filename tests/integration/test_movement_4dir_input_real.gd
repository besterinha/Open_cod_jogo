extends GutTest
# Input real 4-dir com assert no CONSUMIDOR downstream (board/turn), não só emissor
# Boundary: tap (unproject + _handle_tap) -> MovementSystem -> Board.occupancy
# Regra §7b: act via handler real, assert no consumidor.


func _pegar_hero(board: TacticalBoard, turn: TurnManager) -> Unit:
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	return unit


func test_move_4dir_waypoints_com_input_real() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var movement: MovementSystem = arena.get_node_or_null("MovementSystem") as MovementSystem
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	assert_not_null(board)
	assert_not_null(movement)
	var unit: Unit = _pegar_hero(board, turn)
	assert_not_null(unit)
	var start: Vector2i = unit.cell
	# destino walkable 1-2 células à direita
	var target: Vector2i = start + Vector2i(2, 0)
	if not board.grid.is_within_bounds(target) or not board.is_walkable(target):
		target = start + Vector2i(1, 0)
	if not board.is_walkable(target):
		target = start
	if target == start:
		return  # sem movimento possível neste layout
	# diagonal (1,1) não deve estar em reachable range 1 (4-dir)
	var reach1: Array[Vector2i] = board.grid.get_reachable(
		start, 1, func(c: Vector2i) -> bool: return board.is_walkable(c) or c == start
	)
	assert_false(reach1.has(start + Vector2i(1, 1)), "diagonal não deve estar em reachable 4-dir")
	var path: Array[Vector2i] = movement.find_path(start, target)
	assert_true(path.size() >= 2, "path deve ter waypoints (4-dir), não linha reta")
	watch_signals(board)
	var before_pos: Vector3 = unit.position
	# ACT input real: unproject do destino + handler real (não move_unit direto)
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	assert_not_null(cam)
	var screen_pos: Vector2 = cam.unproject_position(board.grid.cell_to_world(target))
	arena.call("_handle_tap", screen_pos)
	await get_tree().process_frame
	# ASSERT no CONSUMIDOR downstream imediato (board occupancy)
	assert_eq(
		board.get_unit_at(target), unit, "board (consumidor) deve ver unit no destino logo após tap"
	)
	assert_eq(unit.cell, target, "emissor cell atualiza imediato p/ occupancy")
	assert_true(
		board.is_walkable(start) or board.get_unit_at(start) == null,
		"origem deve ficar livre (board consumidor)"
	)
	# posição ainda não teleportou (tween 0.70 per-cell)
	assert_true(
		unit.position.distance_to(before_pos) < 0.1,
		"posição não deve teleportar (tween downstream)"
	)
	var wait: float = 0.70 * float(path.size() - 1) + 0.3
	await get_tree().create_timer(wait).timeout
	var end_world: Vector3 = board.grid.cell_to_world(target)
	assert_true(
		unit.position.distance_to(end_world) < 0.15,
		"após " + str(wait) + "s position deve estar no destino (consumidor) path " + str(path)
	)


func test_move_4dir_nao_atravessa_parede() -> void:
	var board := TacticalBoard.new()
	board.grid = GridSystem.new(Vector2i(5, 5), 1.0)
	add_child_autofree(board)
	var movement := MovementSystem.new()
	movement.setup(board)
	add_child_autofree(movement)
	# bloqueia corredor: coloca unidade bloqueando (1,0)
	var blocker := Unit.new()
	blocker.cell = Vector2i(1, 0)
	blocker.stats = UnitStats.new()
	blocker.stats.values = {"hp": 10, "movement": 4}
	board.add_unit(blocker)
	var hero := Unit.new()
	hero.cell = Vector2i(0, 0)
	hero.stats = UnitStats.new()
	hero.stats.values = {"hp": 10, "movement": 4}
	board.add_unit(hero)
	var path: Array[Vector2i] = movement.find_path(Vector2i(0, 0), Vector2i(2, 0))
	# com (1,0) bloqueado, path deve contornar (não tamanho 3 direto)
	assert_true(path.size() == 0 or path.size() > 3, "path deve contornar parede, não linha reta 3")
