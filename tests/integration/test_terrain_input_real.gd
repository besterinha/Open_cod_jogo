extends GutTest
# Input real sobre terreno: tap em bloqueado não move (consumidor board);
# highlights nunca incluem célula bloqueada; dano de piso via tap real


func _arena_com_layout(rows: PackedStringArray, dmg: int = -2) -> Node3D:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var tl: TerrainLayer = arena.get_node_or_null("TerrainLayer") as TerrainLayer
	assert_not_null(tl, "arena deve ter TerrainLayer")
	tl.setup(_make_layout(rows, dmg))
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	board.terrain = tl
	return arena


func _make_layout(rows: PackedStringArray, dmg: int) -> BoardLayoutResource:
	var l := BoardLayoutResource.new()
	l.size = Vector2i(8, 8)
	l.rows = rows
	l.damage_delta = dmg
	return l


func test_tap_em_bloqueado_nao_move_consumidor() -> void:
	var arena: Node3D = await _arena_com_layout(
		[
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
		]
	)
	var board: TacticalBoard = arena.get_node("TacticalBoard")
	var turn: TurnManager = arena.get_node("TurnManager")
	var movement: MovementSystem = arena.get_node("MovementSystem")
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	assert_not_null(unit)
	# ARRANGE: escolhe célula livre/alcance e vira muro (arranjo, não input)
	var reach: Array[Vector2i] = movement.get_reachable(unit)
	reach.erase(unit.cell)
	assert_false(reach.is_empty(), "precisa de ao menos 1 destino alcançável")
	var target: Vector2i = reach[0]
	tl_bloqueia_celula(arena, target)
	assert_false(board.is_walkable(target), "consumidor Board respeita blocked após arrange")
	var cam: Camera3D = arena.get_node("CameraRig/Camera3D")
	watch_signals(board)
	# ACT — tap real na célula bloqueada
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(target)))
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	# ASSERT no consumidor: nada mudou
	assert_null(board.get_unit_at(target), "célula bloqueada nunca ocupada (consumidor)")
	assert_ne(unit.cell, target, "unidade não entrou no bloco")


func tl_bloqueia_celula(arena: Node3D, cell: Vector2i) -> void:
	var tl: TerrainLayer = arena.get_node("TerrainLayer")
	var rows: Array[String] = []
	for y in 8:
		var row := ""
		for x in 8:
			row += "#" if Vector2i(x, y) == cell else "."
		rows.append(row)
	var l := BoardLayoutResource.new()
	l.size = Vector2i(8, 8)
	l.rows = PackedStringArray(rows)
	l.damage_delta = -1
	tl.setup(l)


func test_highlights_nao_mostram_bloqueadas() -> void:
	var arena: Node3D = await _arena_com_layout(
		[
			"..#.....",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
			"........",
		]
	)
	var board: TacticalBoard = arena.get_node("TacticalBoard")
	var turn: TurnManager = arena.get_node("TurnManager")
	var movement: MovementSystem = arena.get_node("MovementSystem")
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	assert_not_null(unit)
	assert_not_null(board.terrain, "board deve ter terreno ativo")
	var blocked_cell := Vector2i(2, 0)
	assert_true(board.terrain.is_blocked(blocked_cell), "arranjo: (2,0) é muro no layout")
	# refresh real de highlights via troca de turno (redesenha com layout atual)
	turn.end_turn()
	await get_tree().process_frame
	await get_tree().process_frame
	var current: Unit = turn.get_current_unit()
	if current.team != 0:
		return  # IA assume — cenário só cobre highlights do time 0
	var reach: Array[Vector2i] = movement.get_reachable(current)
	assert_false(
		reach.has(blocked_cell),
		"alcance de movimento não deve incluir bloqueada (consumidor Movement)"
	)
	for n in get_tree().get_nodes_in_group("highlight"):
		var hl := n as MeshInstance3D
		if hl == null:
			continue
		var cell: Vector2i = board.grid.world_to_cell(hl.position)
		assert_false(
			board.terrain.is_blocked(cell),
			"highlight em %s está sobre célula bloqueada" % str(cell)
		)
