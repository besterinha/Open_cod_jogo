class_name AreaShapeLine
extends AreaShape
# Built-in: linha de 3 células na direção +x a partir do alvo (legado).


func get_cells(_origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if grid.is_within_bounds(target):
		out.append(target)
	for i in range(1, 3):
		var c: Vector2i = target + Vector2i(i, 0)
		if grid.is_within_bounds(c):
			out.append(c)
	return out


func shape_id() -> String:
	return "line"
