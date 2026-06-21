class_name PropertyTestHelper
extends RefCounted

const DEFAULT_ITERATIONS: int = 1000

var _rng: RandomNumberGenerator


func _init() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.randomize()


func generate_random_grid_coordinates(
	count: int,
	min_x: int = -50,
	max_x: int = 50,
	min_y: int = -50,
	max_y: int = 50
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.resize(count)
	for i in range(count):
		result[i] = Vector2i(
			_rng.randi_range(min_x, max_x),
			_rng.randi_range(min_y, max_y)
		)
	return result


func generate_random_float(
	min: float = -1000.0,
	max: float = 1000.0
) -> float:
	return _rng.randf_range(min, max)


func generate_random_vector2(
	min_x: float = -1000.0,
	max_x: float = 1000.0,
	min_y: float = -1000.0,
	max_y: float = 1000.0
) -> Vector2:
	return Vector2(
		_rng.randf_range(min_x, max_x),
		_rng.randf_range(min_y, max_y)
	)


func generate_random_bool() -> bool:
	return _rng.randi() % 2 == 0


func generate_random_int(
	min: int = -1000,
	max: int = 1000
) -> int:
	return _rng.randi_range(min, max)


func assert_invariant(
	description: String,
	test_func: Callable,
	iterations: int = DEFAULT_ITERATIONS
) -> bool:
	for i in range(iterations):
		var ok: bool = test_func.call()
		if not ok:
			push_error(
				"Property invariant failed after %d iteration(s): %s"
				% [i + 1, description]
			)
			return false
	return true
