class_name AreaShapeSingle
extends AreaShape
# Built-in: só a célula mirada.


func get_cells(_origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if grid.is_within_bounds(target):
		out.append(target)
	return out


func shape_id() -> String:
	return "single"
