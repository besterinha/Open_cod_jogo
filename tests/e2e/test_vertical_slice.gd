extends GutTest
# E2E: Jornada 10 dias -> Evento -> Combate 2v2 -> Vitória -> Save

func test_vertical_slice_journey_10_dias() -> void:
	var caravan := CaravanManager.new()
	caravan.supplies = 30
	caravan.morale = 50
	add_child_autofree(caravan)
	var travel := TravelSystem.new()
	travel.setup(caravan)
	add_child_autofree(travel)
	travel.travel(10)
	assert_eq(caravan.day, 11, "10 dias viajados")
	assert_eq(caravan.supplies, 20, "30-10 supplies")
	# morale -10/dia, mas sem suprimento extra, 50-100 => 0? 50-10*10 = -50 => 0 clamp
	assert_true(caravan.morale >= 0)

func test_e2e_combat_2v2_com_3_habilidades() -> void:
	var board := TacticalBoard.new()
	board.grid_size = Vector2i(6, 6)
	board.grid = GridSystem.new(Vector2i(6, 6), 1.0)
	add_child_autofree(board)
	# 2 heroes
	for i in 2:
		var u := Unit.new()
		u.unit_id = "hero%d" % i
		u.display_name = "Hero%d" % i
		u.team = 0
		u.cell = Vector2i(i, 0)
		u.stats = UnitStats.new()
		u.stats.set_stat("hp", 10)
		u.stats.set_stat("willpower", 5)
		board.add_unit(u)
	# 2 enemies com hp baixo e perto para garantir alcance strike 1
	for i in 2:
		var e := Unit.new()
		e.unit_id = "enemy%d" % i
		e.display_name = "Enemy%d" % i
		e.team = 1
		e.cell = Vector2i(0 + i, 1) # (0,1) e (1,1) ao lado dos heroes (0,0) e (1,0)
		e.stats = UnitStats.new()
		e.stats.set_stat("hp", 4) # strike mata em 1 hit
		board.add_unit(e)
	var cm := CombatManager.new()
	cm.setup(board)
	add_child_autofree(cm)
	var strike: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
	var heal: AbilityResource = load("res://data/abilities/heal.tres") as AbilityResource
	var fireball: AbilityResource = load("res://data/abilities/fireball.tres") as AbilityResource
	# strike em inimigo
	var hero: Unit = board.get_units_by_team(0)[0]
	var enemy: Unit = board.get_units_by_team(1)[0]
	watch_signals(cm)
	assert_true(cm.can_use_ability(hero, strike, enemy.cell))
	assert_true(cm.use_ability(hero, strike, enemy.cell))
	assert_signal_emitted(cm, "damage_applied")
	assert_true(enemy.is_defeated(), "strike -4 em 4 hp deve matar")
	# heal em aliado
	var ally: Unit = board.get_units_by_team(0)[1]
	ally.stats.set_stat("hp", 2)
	assert_true(cm.use_ability(hero, heal, ally.cell))
	assert_eq(ally.get_stat("hp"), 7)
	# fireball 3x3 no segundo inimigo
	var enemy2: Unit = board.get_units_by_team(1)[0] # agora só 1 vivo
	if enemy2:
		enemy2.stats.set_stat("hp", 10)
		assert_true(cm.use_ability(hero, fireball, enemy2.cell))
		assert_eq(enemy2.get_stat("hp"), 4, "fireball -6")

func test_e2e_save_apos_vitoria() -> void:
	var data: Dictionary = {"day": 11, "supplies": 20, "morale": 30, "renown": 5, "pop": {"clansmen": 90, "fighters": 20, "varl": 5}}
	SaveSystem.set_data(data)
	assert_true(SaveSystem.save())
	assert_true(SaveSystem.load_save())
	var loaded: Dictionary = SaveSystem.get_data()
	assert_eq(loaded["day"], 11)
	assert_eq(loaded["renown"], 5)
