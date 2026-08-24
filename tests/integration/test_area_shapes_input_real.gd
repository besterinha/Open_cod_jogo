extends GutTest
# Input real T2: cone plugado via HUD (botão real) + tap no alvo — dano em cone no consumidor
# Prova de plugar: conejato.tres apareceu no HUD por glob, sem tocar código


func test_cone_via_hud_tap_acerta_leque() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node("TacticalBoard")
	var turn: TurnManager = arena.get_node("TurnManager")
	var combat: CombatManager = arena.get_node("CombatManager")
	var hud: Control = arena.get_node("CanvasLayer/TacticalHUD")
	await get_tree().process_frame
	# ARRANGE — hero na vez com willpower para o custo
	var hero: Unit = turn.get_current_unit()
	if hero == null or hero.team != 0:
		for u in board.units:
			if u.team == 0 and not u.is_defeated():
				hero = u
				break
	assert_not_null(hero)
	hero.stats.set_stat("willpower", 9)
	# ARRANGE — remove inimigos default via API pública (libera occupancy)
	for u in board.units.duplicate():
		if u.team == 1:
			board.remove_unit(u)
	await get_tree().process_frame
	var enemies: Array[Unit] = []
	# cone length=3 a partir do hero: cobre x=hero.x..+2 com abertura lateral
	var aimed: Vector2i = hero.cell + Vector2i(2, 0)  # alvo do tap (dentro do leque)
	var side_cell: Vector2i = hero.cell + Vector2i(1, 1)  # borda lateral passo 1
	var outside: Vector2i = hero.cell + Vector2i(0, 3)  # fora do cone
	for pair in [[aimed, "Aimed"], [side_cell, "Side"], [outside, "Out"]]:
		var cell: Vector2i = pair[0]
		if not board.is_walkable(cell):
			continue
		var e := Unit.new()
		e.unit_id = "cone_" + str(pair[1]).to_lower()
		e.display_name = str(pair[1])
		e.team = 1
		e.cell = cell
		e.stats = UnitStats.new()
		e.stats.values = {"hp": 20}
		e.position = board.grid.cell_to_world(e.cell)
		board.add_unit(e)
		enemies.append(e)
	assert_true(board.get_unit_at(aimed) != null, "arranjo: alvo mirado precisa existir")
	assert_true(enemies.size() >= 2, "arranjo precisa de inimigos válidos no board")
	# ACT — seleciona conejato pelo botão REAL do HUD (glob T2) e tap no inimigo ao frente
	var cone_btn: Button = hud.get_node_or_null("HBox/conejato") as Button
	assert_not_null(cone_btn, "conejato.tres deve virar botão via glob (plugar = soltar .tres)")
	cone_btn.pressed.emit()
	await get_tree().process_frame
	var cam: Camera3D = arena.get_node("CameraRig/Camera3D")
	watch_signals(combat)
	arena.call("_handle_tap", cam.unproject_position(board.grid.cell_to_world(aimed)))
	await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout
	# ASSERT consumidor Combat/Unit: acertou quem está no leque, errou quem está fora
	assert_signal_emitted(combat, "ability_used", "tap em inimigo com conejato usa habilidade")
	for e in enemies:
		if e.cell == outside:
			assert_eq(e.get_stat("hp"), 20, "inimigo fora do cone NÃO leva dano")
		else:
			assert_eq(e.get_stat("hp"), 16, "%s no leque leva -4 (consumidor hp)" % e.display_name)
