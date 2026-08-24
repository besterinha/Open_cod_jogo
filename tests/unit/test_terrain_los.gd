extends GutTest
# Terreno & LOS: BoardLayout tokens, TerrainLayer walkable, A* ponderado, Bresenham


func _layout(rows: PackedStringArray, dmg: int = -2) -> BoardLayoutResource:
	var l := BoardLayoutResource.new()
	l.size = Vector2i(8, 8)
	l.rows = rows
	l.damage_delta = dmg
	return l


func test_layout_tokens_blocked_cost_damage() -> void:
	var l := _layout(
		[
			"........",
			"..##....",
			"..##..3.",
			"........",
			"....^...",
			"...44...",
			"........",
			"........",
		]
	)
	var errs: Array[String] = BoardLayoutResource.validate(l)
	assert_eq(errs.size(), 0, "layout demo válido: %s" % ", ".join(errs))
	assert_true(l.is_blocked(Vector2i(2, 1)), "# é bloqueado")
	assert_false(l.is_blocked(Vector2i(0, 0)), ". é livre")
	assert_eq(l.move_cost(Vector2i(6, 2)), 3, "token numérico = custo")
	assert_eq(l.move_cost(Vector2i(3, 5)), 4)
	assert_eq(l.move_cost(Vector2i(0, 0)), 1, "default custo 1")
	assert_true(l.is_damage_floor(Vector2i(4, 4)), "^ é piso de dano")
	assert_eq(l.damage_delta, -2)


func test_layout_validate_rejeita_linha_errada_e_token() -> void:
	var bad := _layout(["......", "..x...", "......", "......", "......", "......", "......"])
	bad.size = Vector2i(8, 7)
	var errs: Array[String] = BoardLayoutResource.validate(bad)
	assert_true(errs.size() >= 2, "linha curta + token inválido devem falhar: %s" % str(errs))


func test_terrain_bloqueia_walkable_no_board() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	var tl := TerrainLayer.new()
	tl.setup(_layout(["########"] as PackedStringArray))
	add_child_autofree(tl)
	b.terrain = tl
	add_child_autofree(b)
	for x in 8:
		assert_false(b.is_walkable(Vector2i(x, 0)), "muro na linha 0 não deve ser andável")
	assert_true(b.is_walkable(Vector2i(0, 1)), "fora do layout default é livre")


func test_sem_terreno_grid_todo_livre_compat() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(4, 4)
	b.grid = GridSystem.new(Vector2i(4, 4), 1.0)
	add_child_autofree(b)
	assert_null(b.terrain, "terrain opcional")
	assert_true(b.is_walkable(Vector2i(3, 3)))


func test_asto_ponderado_contorna_custo_alto() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	var tl := TerrainLayer.new()
	# parede de custo 9 no meio: contornar (custo 4+1+4) vale mais que atravessar? não:
	# direta: 9*? atravessar 4 células de custo 9 = 36; contorno por cima = 3 + 3 = 6
	(
		tl
		. setup(
			_layout(
				[
					"........",
					"........",
					"........",
					"....9999",
					"9999.999",
					"........",
					"........",
					"........",
				]
			)
		)
	)
	add_child_autofree(tl)
	b.terrain = tl
	add_child_autofree(b)
	var m := MovementSystem.new()
	m.setup(b)
	add_child_autofree(m)
	var path: Array[Vector2i] = m.find_path(Vector2i(0, 4), Vector2i(7, 4))
	var total := 0
	for i in range(1, path.size()):
		total += tl.move_cost(path[i])
	assert_lt(
		total,
		tl.move_cost(Vector2i(0, 4)) * 7,
		"caminho ponderado deve custar menos que atravessar tudo a 9"
	)
	assert_eq(path[0], Vector2i(0, 4), "path começa na origem")
	assert_eq(path[path.size() - 1], Vector2i(7, 4), "path termina no destino")
	for i in range(1, path.size()):
		var delta: Vector2i = (path[i] - path[i - 1]).abs()
		assert_true(
			delta == Vector2i(1, 0) or delta == Vector2i(0, 1), "passo 4-dir mesmo com terreno"
		)


func test_reachable_orcamento_custo_exclui_carro() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	var tl := TerrainLayer.new()
	(
		tl
		. setup(
			_layout(
				[
					"........",
					"........",
					"........",
					"........",
					"22......",
					"22......",
					"........",
					"........",
				]
			)
		)
	)
	add_child_autofree(tl)
	b.terrain = tl
	add_child_autofree(b)
	var m := MovementSystem.new()
	m.setup(b)
	add_child_autofree(m)
	var hero := Unit.new()
	hero.cell = Vector2i(0, 4)
	hero.stats = UnitStats.new()
	hero.stats.values = {"hp": 10, "movement": 2}
	b.add_unit(hero)
	var reach: Array[Vector2i] = m.get_reachable(hero)
	# movement=2: com células de custo 2, só alcança UMA célula custosa
	var costly: Array[Vector2i] = reach.filter(func(c: Vector2i) -> bool: return c.x >= 1)
	assert_true(reach.has(Vector2i(1, 4)), "célula custo 2 dentro do orçamento 2")
	assert_false(
		reach.has(Vector2i(1, 5)), "segunda célula custo 2 excede orçamento (consumidor Movement)"
	)
	assert_true(costly.size() <= 2, "orçamento limita células custosas")


func test_has_line_of_sight_bresenham() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	var wall := func(c: Vector2i) -> bool: return c == Vector2i(4, 2)
	assert_false(
		g.has_line_of_sight(Vector2i(0, 2), Vector2i(7, 2), wall),
		"muro em (4,2) bloqueia linha (0,2)->(7,2)"
	)
	assert_true(g.has_line_of_sight(Vector2i(0, 2), Vector2i(3, 2), wall), "antes do muro vê")
	assert_true(g.has_line_of_sight(Vector2i(5, 2), Vector2i(7, 2), wall), "depois do muro vê")
	assert_true(
		g.has_line_of_sight(
			Vector2i(0, 2), Vector2i(7, 2), func(c: Vector2i) -> bool: return c == Vector2i(4, 3)
		),
		"opaco fora da rota não bloqueia"
	)
	# extremidades nunca contam como bloqueio
	assert_true(
		g.has_line_of_sight(Vector2i(4, 2), Vector2i(7, 2), wall),
		"origem sobre opaco ainda vê (endpoints ignorados)"
	)
	# muro no meio da diagonal
	var diag_wall := func(c: Vector2i) -> bool: return c == Vector2i(2, 2)
	assert_false(
		g.has_line_of_sight(Vector2i(0, 0), Vector2i(4, 4), diag_wall),
		"muro na diagonal bloqueia visão"
	)
	assert_true(
		g.has_line_of_sight(
			Vector2i(0, 0), Vector2i(4, 4), func(c: Vector2i) -> bool: return false
		),
		"sem opacos, diagonal livre"
	)
	assert_true(
		g.has_line_of_sight(Vector2i(3, 3), Vector2i(3, 3), diag_wall),
		"mesma célula sempre visível"
	)


func test_piso_dano_aplica_ao_entrar_consumidor() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	var tl := TerrainLayer.new()
	tl.setup(_layout(["^^^^^^^^"], -3))
	add_child_autofree(tl)
	b.terrain = tl
	add_child_autofree(b)
	var m := MovementSystem.new()
	m.setup(b)
	add_child_autofree(m)
	var hero := Unit.new()
	hero.display_name = "Hero"
	hero.cell = Vector2i(0, 0)
	# origem FORA do piso; destino no piso
	hero.stats = UnitStats.new()
	hero.stats.values = {"hp": 10, "movement": 4}
	b.add_unit(hero)
	watch_signals(tl)
	m.move_unit(hero, Vector2i(3, 0))
	await get_tree().process_frame
	assert_eq(
		hero.get_stat("hp"), 7, "piso de dano deve aplicar -3 ao entrar (consumidor Unit.stats)"
	)
	assert_signal_emitted(tl, "damage_floor_triggered")
