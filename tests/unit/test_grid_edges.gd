extends GutTest
# Buracos de cobertura do grid: roundtrip world/cell, negativos, áreas cross/line,
# remove_unit/derrota limpa occupancy, validade do path (adjacência + otimalidade)


func _board_8() -> TacticalBoard:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	add_child_autofree(b)
	return b


func test_cell_world_roundtrip_e_offset_centro() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	var w: Vector3 = g.cell_to_world(Vector2i(2, 3))
	assert_eq(w, Vector3(2.5, 0.0, 3.5), "centro da célula deve ter offset +0.5")
	assert_eq(g.world_to_cell(w), Vector2i(2, 3), "roundtrip cell->world->cell")
	for c in [Vector2i(0, 0), Vector2i(7, 7), Vector2i(4, 1)]:
		assert_eq(g.world_to_cell(g.cell_to_world(c)), c, "roundtrip %s" % str(c))


func test_floor_negativos_e_bounds() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	var cell: Vector2i = g.world_to_cell(Vector3(-0.5, 0.0, -0.5))
	assert_eq(cell, Vector2i(-1, -1), "floor(-0.5) = -1")
	assert_false(g.is_within_bounds(cell), "célula negativa fora dos bounds")
	assert_true(g.is_within_bounds(Vector2i(7, 7)), "última célula dentro")
	assert_false(g.is_within_bounds(Vector2i(8, 8)), "além do grid fora")
	assert_false(g.is_within_bounds(Vector2i(-1, 0)), "x negativo fora")


func test_get_area_cross_line_e_fallback() -> void:
	var b := _board_8()
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var cross: Array[Vector2i] = cm.get_area_cells(Vector2i(2, 2), "cross")
	assert_eq(cross.size(), 5, "cross = centro + 4 vizinhos")
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		assert_true(cross.has(Vector2i(2, 2) + d), "cross deve conter vizinho %s" % str(d))
	var line: Array[Vector2i] = cm.get_area_cells(Vector2i(0, 0), "line")
	assert_eq(line.size(), 3, "line = origem + 2 na direção +x")
	assert_eq(line[2], Vector2i(2, 0))
	var line_edge: Array[Vector2i] = cm.get_area_cells(Vector2i(6, 0), "line")
	assert_eq(
		line_edge,
		[Vector2i(6, 0), Vector2i(7, 0)],
		"line perto da borda trunca células fora do grid"
	)
	var unknown: Array[Vector2i] = cm.get_area_cells(Vector2i(1, 1), "banana")
	assert_eq(unknown, [Vector2i(1, 1)], "área desconhecida cai em single")


func test_remove_unit_limpa_occupancy() -> void:
	var b := _board_8()
	var u := Unit.new()
	u.stats = UnitStats.new()
	u.stats.set_stat("hp", 10)
	u.cell = Vector2i(3, 3)
	b.add_unit(u)
	watch_signals(b)
	b.remove_unit(u)
	await get_tree().process_frame
	assert_null(b.get_unit_at(Vector2i(3, 3)), "occupancy deve limpar no remove_unit")
	assert_true(b.is_walkable(Vector2i(3, 3)), "célula volta a ser andável (consumidor)")
	assert_signal_emitted(b, "unit_removed")


func test_derrotado_libera_celula_andavel() -> void:
	var b := _board_8()
	var u := Unit.new()
	u.display_name = "Mortal"
	u.stats = UnitStats.new()
	u.stats.values = {"hp": 5}
	b.add_unit(u)
	watch_signals(b)
	u.modify_stat("hp", -5)
	await get_tree().process_frame
	assert_true(u.is_defeated(), "hp<=0 derrota")
	assert_null(b.get_unit_at(u.cell), "occupancy do derrotado liberada (consumidor Board)")
	assert_true(b.is_walkable(u.cell), "célula de morto é andável")
	assert_signal_emitted(b, "unit_removed", "derrota deve emitir unit_removed")


func test_find_path_adjacente_e_otimo() -> void:
	var b := _board_8()
	var m := MovementSystem.new()
	m.setup(b)
	add_child_autofree(m)
	var from := Vector2i(0, 0)
	var to := Vector2i(3, 2)
	var path: Array[Vector2i] = m.find_path(from, to)
	assert_true(path.size() >= 2, "path não vazio")
	assert_eq(path[0], from, "path começa na origem")
	assert_eq(path[path.size() - 1], to, "path termina no destino")
	assert_eq(path.size() - 1, 5, "comprimento ótimo = Manhattan |3|+|2|")
	for i in range(1, path.size()):
		var delta: Vector2i = (path[i] - path[i - 1]).abs()
		assert_true(
			delta == Vector2i(1, 0) or delta == Vector2i(0, 1),
			"passo %d deve ser vizinho 4-dir, não diagonal" % i
		)
