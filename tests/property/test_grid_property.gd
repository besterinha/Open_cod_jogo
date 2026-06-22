extends GdUnitTestSuite

const ITERATIONS: int = 1000


func test_grid_roundtrip_invariant() -> void:
	var helper := PropertyTestHelper.new()
	var grid := GridSystem.new()
	var coords := helper.generate_random_grid_coordinates(
		ITERATIONS, 0, 7, 0, 7
	)
	for coord in coords:
		var world := grid.grid_to_world(coord)
		var back := grid.world_to_grid(world)
		assert_vector2i(back).is_equal(coord)


func test_is_within_bounds_consistency() -> void:
	var helper := PropertyTestHelper.new()
	var grid := GridSystem.new()
	var coords := helper.generate_random_grid_coordinates(
		ITERATIONS, -50, 50, -50, 50
	)
	for coord in coords:
		var result := grid.is_within_bounds(coord)
		var expected := (
			coord.x >= 0 and coord.x < 8
			and coord.y >= 0 and coord.y < 8
		)
		assert_bool(result).is_equal(expected)


func test_grid_to_world_deterministic() -> void:
	var grid := GridSystem.new()
	for i in range(ITERATIONS):
		var coord := Vector2i(i % 8, i / 8)
		var first := grid.grid_to_world(coord)
		var second := grid.grid_to_world(coord)
		assert_float(first.x).is_equal(second.x)
		assert_float(first.y).is_equal(second.y)
