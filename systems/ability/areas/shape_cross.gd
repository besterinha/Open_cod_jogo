class_name AreaShapeCross
extends AreaShape
# Built-in: cruz (centro + 4 vizinhos).


func get_cells(_origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if grid.is_within_bounds(target):
		out.append(target)
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = target + d
		if grid.is_within_bounds(c):
			out.append(c)
	return out


func shape_id() -> String:
	return "cross"
