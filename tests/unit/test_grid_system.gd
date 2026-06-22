extends GdUnitTestSuite


func test_world_to_grid_origin() -> void:
	var grid := GridSystem.new()
	var result := grid.world_to_grid(Vector2(0, 0))
	assert_vector2i(result).is_equal(Vector2i(0, 0))


func test_grid_to_world_returns_vector2() -> void:
	var grid := GridSystem.new()
	var result: Variant = grid.grid_to_world(Vector2i(0, 0))
	assert_int(typeof(result)).is_equal(TYPE_VECTOR2)


func test_world_to_grid_returns_vector2i() -> void:
	var grid := GridSystem.new()
	var result: Variant = grid.world_to_grid(Vector2(0, 0))
	assert_int(typeof(result)).is_equal(TYPE_VECTOR2I)


func test_grid_to_world_zero() -> void:
	var grid := GridSystem.new()
	var result := grid.grid_to_world(Vector2i(0, 0))
	assert_float(result.x).is_equal(0.0)
	assert_float(result.y).is_equal(0.0)


func test_grid_to_world_positive() -> void:
	var grid := GridSystem.new()
	var result := grid.grid_to_world(Vector2i(1, 0))
	assert_float(result.x).is_equal(16.0)
	assert_float(result.y).is_equal(8.0)


func test_grid_to_world_negative() -> void:
	var grid := GridSystem.new()
	var result := grid.grid_to_world(Vector2i(-1, -1))
	assert_float(result.x).is_equal(0.0)
	assert_float(result.y).is_equal(-16.0)


func test_is_within_bounds_origin() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(0, 0))).is_true()


func test_is_within_bounds_max() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(7, 7))).is_true()


func test_is_within_bounds_negative_x() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(-1, 0))).is_false()


func test_is_within_bounds_negative_y() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(0, -1))).is_false()


func test_is_within_bounds_over_x() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(8, 0))).is_false()


func test_is_within_bounds_over_y() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(0, 8))).is_false()


func test_is_within_bounds_diagonal_out() -> void:
	var grid := GridSystem.new()
	assert_bool(grid.is_within_bounds(Vector2i(8, 8))).is_false()


func test_setup_changes_grid_size() -> void:
	var grid := GridSystem.new()
	grid.setup(Vector2i(10, 12))
	assert_int(grid.grid_size.x).is_equal(10)
	assert_int(grid.grid_size.y).is_equal(12)
	assert_bool(grid.is_within_bounds(Vector2i(9, 11))).is_true()
	assert_bool(grid.is_within_bounds(Vector2i(10, 11))).is_false()


func test_hero_teleport_updates_grid_position() -> void:
	var hero := Hero.new()
	hero.teleport_to(Vector2i(3, 4))
	assert_int(hero.grid_position.x).is_equal(3)
	assert_int(hero.grid_position.y).is_equal(4)
	hero.queue_free()


func test_hero_teleport_with_grid_system() -> void:
	var grid := GridSystem.new()
	var hero := Hero.new()
	hero.grid_system = grid
	hero.teleport_to(Vector2i(2, 3))
	var expected := grid.grid_to_world(Vector2i(2, 3))
	assert_float(hero.position.x).is_equal(expected.x)
	assert_float(hero.position.y).is_equal(expected.y)
	hero.queue_free()


func test_hero_teleport_without_grid() -> void:
	var hero := Hero.new()
	hero.grid_system = null
	hero.teleport_to(Vector2i(5, 6))
	assert_int(hero.grid_position.x).is_equal(5)
	assert_int(hero.grid_position.y).is_equal(6)
	hero.queue_free()
