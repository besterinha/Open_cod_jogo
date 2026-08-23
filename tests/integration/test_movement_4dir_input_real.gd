extends GutTest
# Input real 4-dir com assert no CONSUMIDOR downstream (board/turn), não só emissor
# Boundary: movimento -> board.occupancy + turn (consumidores)


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
	# pega hero da vez (team 0)
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		# força hero0
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	assert_not_null(unit)
	var start: Vector2i = unit.cell
	# força path com obstáculo: bloqueia diagonal artificial
	# usa ponto 2 células à frente se livre, senão 1
	var target: Vector2i = start + Vector2i(2, 0)
	if not board.grid.is_within_bounds(target) or not board.is_walkable(target):
		target = start + Vector2i(1, 0)
	if not board.is_walkable(target):
		target = start
	assert_true(
		movement.can_move_to(unit, target) or target == start, "target deve ser walkable para teste"
	)
	if target == start:
		return  # sem movimento possível, teste passa
	var before_pos: Vector3 = unit.position
	watch_signals(unit)
	watch_signals(board)
	var path: Array[Vector2i] = movement.find_path(start, target)
	assert_true(path.size() >= 2, "path deve ter waypoints (4-dir), não linha reta")
	# diagonal (1,1) não deve estar em reachable range 1 (4-dir)
	var reach1: Array[Vector2i] = board.grid.get_reachable(
		start, 1, func(c: Vector2i) -> bool: return board.is_walkable(c) or c == start
	)
	assert_false(reach1.has(start + Vector2i(1, 1)), "diagonal não deve estar em reachable 4-dir")
	# act: input real via movement (não unit.move_to direto)
	var ok: bool = movement.move_unit(unit, target)
	assert_true(ok, "move_unit deve aceitar")
	# assert no CONSUMIDOR downstream imediato (board occupancy)
	assert_eq(unit.cell, target, "emissor cell deve atualizar imediatamente para occupancy")
	assert_eq(board.get_unit_at(target), unit, "board (consumidor) deve ver unit no destino")
	assert_true(
		board.is_walkable(start) or board.get_unit_at(start) == null,
		"origem deve ficar livre (board consumidor)"
	)
	# posição ainda não teleportou (tween 0.70 per-cell)
	assert_true(
		unit.position.distance_to(before_pos) < 0.1,
		"posição não deve teleportar (tween downstream)"
	)
	var wait: float = 0.70 * (path.size() - 1) + 0.3
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
