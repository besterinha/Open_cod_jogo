extends GutTest
# Testa GridSystem — garante que nova lógica não quebra movimento/área de magia.


func test_world_to_cell() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	assert_eq(g.world_to_cell(Vector3(0.5, 0, 0.5)), Vector2i(0, 0))
	assert_eq(g.world_to_cell(Vector3(7.9, 0, 7.9)), Vector2i(7, 7))


func test_is_within_bounds() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	assert_true(g.is_within_bounds(Vector2i(0, 0)))
	assert_false(g.is_within_bounds(Vector2i(8, 0)))
	assert_false(g.is_within_bounds(Vector2i(-1, 0)))


func test_reachable_range_1() -> void:
	var g := GridSystem.new(Vector2i(8, 8), 1.0)
	var reachable: Array[Vector2i] = g.get_reachable(
		Vector2i(4, 4), 1, func(_c: Vector2i) -> bool: return true
	)
	# origem + 4 vizinhos = 5
	assert_eq(reachable.size(), 5)


func test_reachable_blocked() -> void:
	var g := GridSystem.new(Vector2i(3, 3), 1.0)
	var reachable: Array[Vector2i] = g.get_reachable(
		Vector2i(1, 1), 2, func(c: Vector2i) -> bool: return c != Vector2i(2, 1)
	)
	# (2,1) bloqueado, então não deve aparecer
	assert_false(reachable.has(Vector2i(2, 1)))
