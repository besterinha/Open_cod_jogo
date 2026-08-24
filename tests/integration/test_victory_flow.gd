extends GutTest
# Fluxo de vitória: derrota de ambos inimigos -> battle_ended no consumidor Turn
# Wiring real: unit_defeated -> check_victory (mesmo wiring da TacticalArena)


func test_vitoria_emite_battle_ended_time0() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(5, 5)
	b.grid = GridSystem.new(Vector2i(5, 5), 1.0)
	add_child_autofree(b)

	var hero := Unit.new()
	hero.unit_id = "hero"
	hero.display_name = "Hero"
	hero.team = 0
	hero.cell = Vector2i(0, 0)
	hero.stats = UnitStats.new()
	hero.stats.values = {"hp": 10, "willpower": 9}
	b.add_unit(hero)
	var enemies: Array[Unit] = []
	var cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1)]  # ambos alcance 1 do hero
	for i in 2:
		var e := Unit.new()
		e.unit_id = "e%d" % i
		e.display_name = "Enemy%d" % i
		e.team = 1
		e.cell = cells[i]
		e.stats = UnitStats.new()
		e.stats.values = {"hp": 3}
		b.add_unit(e)
		enemies.append(e)
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var turn := TeamRoundRobin.new()
	turn.setup(b)
	add_child_autofree(turn)
	# mesmo wiring da arena: derrota consulta vitória (consumidor TurnManager)
	for u in b.units:
		u.unit_defeated.connect(func(_x: Unit) -> void: turn.check_victory())
	var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
	watch_signals(turn)
	# mata 1º inimigo — ainda há 1 vivo, sem vitória
	var ok1: bool = cm.use_ability(hero, abil, enemies[0].cell)
	assert_true(ok1)
	assert_true(enemies[0].is_defeated(), "primeiro inimigo derrotado")
	await get_tree().process_frame
	assert_signal_not_emitted(turn, "battle_ended", "com 1 inimigo vivo não deve terminar batalha")
	assert_false(b.is_victory(0), "consumidor Board: não é vitória ainda")
	# mata 2º — check_victory via wiring emite battle_ended(0)
	var ok2: bool = cm.use_ability(hero, abil, enemies[1].cell)
	assert_true(ok2)
	assert_true(enemies[1].is_defeated())
	await get_tree().process_frame
	assert_signal_emitted(turn, "battle_ended", "último inimigo morto dispara fim")
	assert_signal_emit_count(turn, "battle_ended", 1)
	assert_true(b.is_victory(0), "consumidor Board confirma vitória do time 0")
	# guarda anti-duplo-emissão: end_turn pós-vitória (_next_turn consulta check_victory) não reemite
	turn.end_turn()
	await get_tree().process_frame
	assert_signal_emit_count(turn, "battle_ended", 1, "guarda: battle_ended só uma vez")
