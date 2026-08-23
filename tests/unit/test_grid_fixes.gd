extends GutTest
# Testa fixes 1-5 do Grid: occupancy morto, fonte única, highlight, input, perf


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
	return u


func test_dead_cell_becomes_walkable() -> void:
	var b := _make_board()
	var u := _make_unit("dead", 0, Vector2i(2, 2), 1)
	b.add_unit(u)
	assert_false(b.is_walkable(Vector2i(2, 2)))
	u.modify_stat("hp", -10)
	assert_true(u.is_defeated())
	# após derrotado, board deve liberar célula
	assert_true(b.is_walkable(Vector2i(2, 2)), "célula de morto deve ficar andável")


func test_update_occupancy_blocks_occupied() -> void:
	var b := _make_board()
	var a := _make_unit("a", 0, Vector2i(1, 1))
	var c := _make_unit("c", 0, Vector2i(1, 2))
	b.add_unit(a)
	b.add_unit(c)
	# tentar mover a para célula ocupada por c deve falhar via is_walkable
	assert_false(b.is_walkable(Vector2i(1, 2)))
	# update_occupancy deve bloquear e não sobrescrever
	b.update_occupancy(a, Vector2i(1, 1), Vector2i(1, 2))
	# a ainda deve estar em (1,1) no occupancy, c em (1,2)
	assert_eq(b.get_unit_at(Vector2i(1, 1)), a)
	assert_eq(b.get_unit_at(Vector2i(1, 2)), c)


func test_grid_single_source() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(6, 6)
	b.grid = GridSystem.new(b.grid_size, 1.0)
	add_child_autofree(b)
	assert_eq(b.grid.size, Vector2i(6, 6))
	assert_eq(b.grid_size, Vector2i(6, 6))
	# mudar grid_size deve refletir após recriar grid
	b.grid_size = Vector2i(10, 10)
	b.grid = GridSystem.new(b.grid_size, 1.0)
	assert_eq(b.grid.size, Vector2i(10, 10))
