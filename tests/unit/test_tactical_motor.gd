extends GutTest
# Testa Motor Tático Genérico — prova não travado em Banner Saga.


func _make_board() -> TacticalBoard:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(5, 5)
	b.grid = GridSystem.new(Vector2i(5, 5), 1.0)
	add_child_autofree(b)
	return b


func _make_unit(id: String, team: int, cell: Vector2i, hp: int = 10) -> Unit:
	var u := Unit.new()
	u.unit_id = id
	u.display_name = id
	u.team = team
	u.cell = cell
	u.stats = UnitStats.new()
	u.stats.set_stat("hp", hp)
	u.stats.set_stat("movement", 3)
	u.stats.set_stat("armor", 2)
	u.stats.set_stat("willpower", 3)
	# não adiciona no tree aqui — TacticalBoard.add_unit fará add_child
	return u


func test_unit_genérico_stats() -> void:
	var u := _make_unit("hero", 0, Vector2i(0, 0), 10)
	add_child_autofree(u)
	assert_eq(u.get_stat("hp"), 10)
	u.modify_stat("hp", -3)
	assert_eq(u.get_stat("hp"), 7)
	assert_false(u.is_defeated())
	u.modify_stat("hp", -10)
	assert_true(u.is_defeated())


func test_board_occupancy() -> void:
	var b := _make_board()
	var u := _make_unit("a", 0, Vector2i(1, 1))
	b.add_unit(u)
	assert_eq(b.get_unit_at(Vector2i(1, 1)), u)
	assert_false(b.is_walkable(Vector2i(1, 1)))
	assert_true(b.is_walkable(Vector2i(2, 2)))


func test_movement_reachable() -> void:
	var b := _make_board()
	var u := _make_unit("mover", 0, Vector2i(2, 2))
	b.add_unit(u)
	var mv := MovementSystem.new()
	mv.setup(b)
	var reach: Array[Vector2i] = mv.get_reachable(u)
	assert_true(reach.has(Vector2i(2, 2)), "origem deve estar no alcance")
	assert_true(reach.size() > 1)
	# bloqueia uma célula com outra unidade
	var blocker := _make_unit("block", 0, Vector2i(3, 2))
	b.add_unit(blocker)
	var reach2: Array[Vector2i] = mv.get_reachable(u)
	assert_false(reach2.has(Vector2i(3, 2)), "bloqueado não deve ser alcançável")
	mv.free()


func test_movement_path() -> void:
	var b := _make_board()
	var u := _make_unit("pather", 0, Vector2i(0, 0))
	b.add_unit(u)
	var mv := MovementSystem.new()
	mv.setup(b)
	var path: Array[Vector2i] = mv.find_path(Vector2i(0, 0), Vector2i(2, 0))
	assert_eq(path[0], Vector2i(0, 0))
	assert_eq(path[-1], Vector2i(2, 0))
	assert_true(path.size() >= 3)
	mv.free()


func test_turn_manager_round_robin() -> void:
	var b := _make_board()
	var u1 := _make_unit("a1", 0, Vector2i(0, 0))
	var u2 := _make_unit("a2", 0, Vector2i(1, 0))
	var e1 := _make_unit("e1", 1, Vector2i(4, 4))
	b.add_unit(u1)
	b.add_unit(u2)
	b.add_unit(e1)
	var tm := TeamRoundRobin.new()
	tm.setup(b)
	add_child_autofree(tm)
	var order: Array[String] = []
	tm.turn_started.connect(func(u: Unit) -> void: order.append(u.unit_id))
	tm.start_battle()
	# deve começar com time 0
	assert_eq(order[0], "a1")
	tm.end_turn()
	assert_eq(order[1], "a2")
	tm.end_turn()
	assert_eq(order[2], "e1")


func test_initiative_turn_orders_by_stat() -> void:
	var b := _make_board()
	var slow := _make_unit("slow", 0, Vector2i(0, 0))
	slow.stats.set_stat("movement", 1)
	var fast := _make_unit("fast", 1, Vector2i(1, 0))
	fast.stats.set_stat("movement", 10)
	b.add_unit(slow)
	b.add_unit(fast)
	var tm := InitiativeTurn.new()
	tm.init_stat_id = "movement"
	tm.setup(b)
	add_child_autofree(tm)
	var order: Array[String] = []
	tm.turn_started.connect(func(u: Unit) -> void: order.append(u.unit_id))
	tm.start_battle()
	assert_true(order.size() > 0, "order não deve estar vazio")
	if order.size() > 0:
		assert_eq(order[0], "fast", "mais rápido primeiro")


func test_combat_manager_genérico_custo_e_dano() -> void:
	var b := _make_board()
	var atk := _make_unit("atk", 0, Vector2i(0, 0))
	atk.stats.set_stat("willpower", 5)
	var def := _make_unit("def", 1, Vector2i(1, 0), 10)
	def.stats.set_stat("armor", 2)
	b.add_unit(atk)
	b.add_unit(def)
	var cm := CombatManager.new()
	var resolver: CombatResolver = load("res://gyms/resolvers/resolver_banner_saga.gd").new()
	cm.setup(b, resolver)
	add_child_autofree(cm)
	# fireball custo willpower 2, dano 6 hp
	var abil := AbilityResource.new()
	abil.id = "test_fire"
	abil.nome = "Teste"
	abil.custo = {"willpower": 2}
	abil.alcance = 5
	abil.area = "single"
	abil.efeitos = [{"stat_id": "hp", "delta": -6}]
	var before_wp: int = atk.get_stat("willpower")
	var before_hp: int = def.get_stat("hp")
	assert_true(cm.can_use_ability(atk, abil, def.cell))
	assert_true(cm.use_ability(atk, abil, def.cell))
	assert_eq(atk.get_stat("willpower"), before_wp - 2, "custo genérico descontado")
	# banner saga: 6 -2 armor =4 dano
	assert_eq(def.get_stat("hp"), before_hp - 4)


func test_combat_manager_rejeita_sem_custo() -> void:
	var b := _make_board()
	var atk := _make_unit("atk2", 0, Vector2i(0, 0))
	atk.stats.set_stat("willpower", 0)
	var def := _make_unit("def2", 1, Vector2i(1, 0))
	b.add_unit(atk)
	b.add_unit(def)
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var abil := AbilityResource.new()
	abil.id = "costly"
	abil.custo = {"willpower": 1}
	abil.alcance = 1
	abil.area = "single"
	abil.efeitos = [{"stat_id": "hp", "delta": -5}]
	assert_false(cm.can_use_ability(atk, abil, def.cell))
	assert_false(cm.use_ability(atk, abil, def.cell))


func test_ai_genérica_foca_hp_baixo() -> void:
	var b := _make_board()
	var ai_unit := _make_unit("ai", 1, Vector2i(0, 0))
	var low := _make_unit("low", 0, Vector2i(4, 4), 2)
	var high := _make_unit("high", 0, Vector2i(4, 3), 10)
	b.add_unit(ai_unit)
	b.add_unit(low)
	b.add_unit(high)
	var ai := preload("res://systems/tactical/ai/aggressive_ai.gd").new()
	ai.focus_stat_id = "hp"
	var intent: Dictionary = ai.generate_intent(ai_unit, b)
	assert_eq(intent["target_unit"], low, "AI deve focar hp baixo")
