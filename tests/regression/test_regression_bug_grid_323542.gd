extends GutTest
# Regression para 323542: dead cell vazava occupancy + grid não era fonte única + highlight poluído
# Cobre A5/C8: se voltar a falhar, gut falha.


func test_regression_grid_dead_walkable() -> void:
	var board := TacticalBoard.new()
	board.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	add_child_autofree(board)
	var u := Unit.new()
	u.cell = Vector2i(1, 2)
	u.stats = UnitStats.new()
	u.stats.values = {"hp": 0, "movement": 4}
	board.add_unit(u)
	# hp 0 = defeated -> is_walkable deve ignorar
	assert_true(board.is_walkable(Vector2i(1, 2)), "dead cell deve ser walkable (323542)")


func test_regression_grid_single_source() -> void:
	var board := TacticalBoard.new()
	board.grid_size = Vector2i(6, 6)
	board.grid = GridSystem.new(board.grid_size, board.cell_size)
	add_child_autofree(board)
	assert_eq(board.grid.size, board.grid_size, "TacticalBoard.grid_size deve ser fonte única")
