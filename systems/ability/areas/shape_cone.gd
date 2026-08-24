class_name AreaShapeCone
extends AreaShape
# Cone abrindo do usuário na direção do alvo. Comprimento = length, largura cresce 1 célula
# por passo no eixo dominante da direção (aproximação barata de SRPG, determinística).

@export var length: int = 3


func get_cells(origin: Vector2i, target: Vector2i, grid: GridSystem) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var delta: Vector2i = target - origin
	if delta == Vector2i.ZERO:
		return get_cells(origin, target + Vector2i(1, 0), grid)
	var dir := Vector2i(signi(delta.x), signi(delta.y))
	# frente = eixo dominante da direção; lateral abre perpendicular
	var fwd := Vector2i(dir.x, 0) if absi(delta.x) > absi(delta.y) else Vector2i(0, dir.y)
	var side := Vector2i(fwd.y, fwd.x)
	for step in range(0, maxi(1, length)):
		var base: Vector2i = origin + fwd * step
		for w in range(-step, step + 1):
			var c: Vector2i = base + side * w
			if grid.is_within_bounds(c):
				out.append(c)
	return out


func shape_id() -> String:
	return "cone"
