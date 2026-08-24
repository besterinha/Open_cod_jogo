class_name AreaShape3x3
extends AreaShape
# Built-in: quadrado 3x3 centrado no alvo.


func get_cells(_origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var c: Vector2i = target + Vector2i(dx, dy)
			if grid.is_within_bounds(c):
				out.append(c)
	return out


func shape_id() -> String:
	return "3x3"
