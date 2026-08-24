class_name AreaShapeRing
extends AreaShape
# Anel ao redor do alvo: células a distância Manhattan exatamente radius (buraco no centro).

@export var radius: int = 2


func get_cells(_origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r: int = maxi(1, radius)
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			if absi(dx) + absi(dy) != r:
				continue
			var c: Vector2i = target + Vector2i(dx, dy)
			if grid.is_within_bounds(c):
				out.append(c)
	return out


func shape_id() -> String:
	return "ring"
