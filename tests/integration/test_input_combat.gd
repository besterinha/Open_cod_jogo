extends GutTest
# Integração Input -> Combat via handler real (§7b): HUD botão -> _handle_tap raycast
# Assert no CONSUMIDOR downstream (Combat signals + hp do alvo + Turn avançou)


func test_tap_em_inimigo_dispara_combate_input_real() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	var combat: CombatManager = arena.get_node_or_null("CombatManager") as CombatManager
	var turn: TurnManager = arena.get_node_or_null("TurnManager") as TurnManager
	assert_not_null(board)
	assert_not_null(combat)
	var hero: Unit = turn.get_current_unit()
	if hero == null or hero.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				hero = u
				break
	assert_not_null(hero)
	var enemy: Unit = null
	for u in board.units:
		if u.team == 1 and not u.is_defeated():
			enemy = u
			break
	assert_not_null(enemy)
	# ARRANGE: aproxima inimigo p/ alcance 1 do hero (arranjo não é input)
	var nb: Vector2i = hero.cell + Vector2i(1, 0)
	if not board.grid.is_within_bounds(nb) or not board.is_walkable(nb):
		nb = hero.cell + Vector2i(0, 1)
	assert_true(board.is_walkable(nb), "vizinho do hero deve estar livre para o arrange")
	var old_enemy_cell: Vector2i = enemy.cell
	board.update_occupancy(enemy, old_enemy_cell, nb)
	enemy.cell = nb
	enemy.position = board.grid.cell_to_world(nb)
	# ACT 1 — seleciona habilidade pelo botão real do HUD (boundary UI)
	var hud: Control = arena.get_node_or_null("CanvasLayer/TacticalHUD") as Control
	assert_not_null(hud, "HUD deve existir na arena")
	await get_tree().process_frame
	var strike_btn: Button = hud.get_node_or_null("HBox/strike") as Button
	assert_not_null(strike_btn, "botão strike deve existir no HUD")
	strike_btn.pressed.emit()
	await get_tree().process_frame
	# ACT 2 — tap real na célula do inimigo via unproject + handler
	var cam: Camera3D = arena.get_node_or_null("CameraRig/Camera3D") as Camera3D
	assert_not_null(cam)
	var screen_pos: Vector2 = cam.unproject_position(board.grid.cell_to_world(enemy.cell))
	watch_signals(combat)
	var before_hp: int = enemy.get_stat("hp")
	arena.call("_handle_tap", screen_pos)
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	# ASSERT no CONSUMIDOR downstream
	assert_signal_emitted(combat, "ability_used", "tap em inimigo deve usar habilidade")
	assert_signal_emitted(combat, "damage_applied", "dano deve chegar ao consumidor Combat")
	assert_eq(enemy.get_stat("hp"), before_hp - 4, "strike -4 no consumidor Unit.stats")
	assert_ne(
		turn.get_current_unit(),
		hero,
		"turno deve passar após ataque bem-sucedido (consumidor Turn)"
	)


func test_tap_fora_alcance_nao_consume() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	add_child_autofree(b)
	var atk := Unit.new()
	atk.unit_id = "atk"
	atk.display_name = "Atk"
	atk.team = 0
	atk.cell = Vector2i(0, 0)
	atk.stats = UnitStats.new()
	atk.stats.set_stat("hp", 10)
	atk.stats.set_stat("willpower", 5)
	atk.stats.set_stat("movement", 3)
	b.add_unit(atk)
	var def := Unit.new()
	def.unit_id = "def"
	def.display_name = "Def"
	def.team = 1
	def.cell = Vector2i(7, 7)
	def.stats = UnitStats.new()
	def.stats.set_stat("hp", 10)
	b.add_unit(def)
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource  # alc 1
	var before_wp: int = atk.get_stat("willpower")
	watch_signals(cm)
	var ok: bool = cm.use_ability(atk, abil, def.cell)  # longe
	assert_false(ok, "fora do alcance não deve usar")
	assert_signal_not_emitted(cm, "ability_used")
	assert_eq(atk.get_stat("willpower"), before_wp, "sem custo se falhou")
