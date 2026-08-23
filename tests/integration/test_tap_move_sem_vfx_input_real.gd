extends GutTest
# Input real: tap move não deve gerar VFX explosão — assert no CONSUMIDOR (Combat + Board)
# Boundary: Input -> TacticalArena._handle_tap -> MovementSystem (consumidor) vs CombatManager (não deve)

func test_tap_move_vazio_sem_vfx_no_consumidor() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var movement: MovementSystem = arena.get_node_or_null("MovementSystem") as MovementSystem
	var combat: CombatManager = arena.get_node_or_null("CombatManager") as CombatManager
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	assert_not_null(board)
	assert_not_null(combat)
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				unit = u
				break
	assert_not_null(unit)
	# escolhe destino vazio walkable a 1 célula
	var target: Vector2i = unit.cell + Vector2i(1, 0)
	if not board.grid.is_within_bounds(target) or not board.is_walkable(target):
		target = unit.cell + Vector2i(0, 1)
	assert_true(board.is_walkable(target), "destino deve ser walkable")
	watch_signals(combat)
	# input real: simula tap no centro do target cell (via ray)
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	assert_not_null(cam)
	var world: Vector3 = board.grid.cell_to_world(target)
	var screen_pos: Vector2 = cam.unproject_position(world)
	# chama handler real (não combat.use_ability direto)
	arena.call("_handle_tap", screen_pos)
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	# assert no CONSUMIDOR: Combat não deve ter emitido ability_used (explosão)
	assert_signal_not_emitted(combat, "ability_used", "tap move não deve emitir VFX explosão no consumidor Combat")
	assert_signal_not_emitted(combat, "damage_applied")
	# consumidor Board deve ter movido
	assert_eq(unit.cell, target, "board consumidor deve ter unit no destino após tap move")

func test_tap_proprio_tile_sem_explosao() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var combat: CombatManager = arena.get_node_or_null("CombatManager") as CombatManager
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	var unit: Unit = turn.get_current_unit()
	if unit == null or unit.team != 0:
		for u in board.units:
			if u.team == 0:
				unit = u
				break
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	var screen_pos: Vector2 = cam.unproject_position(board.grid.cell_to_world(unit.cell))
	watch_signals(combat)
	arena.call("_handle_tap", screen_pos)
	await get_tree().process_frame
	assert_signal_not_emitted(combat, "ability_used", "tap próprio tile não deve explodir (consumidor Combat)")
