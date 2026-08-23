class_name GridSystem
extends RefCounted
# Grid quadrado 2.5D isométrico — agnóstico de rendering.
# Usado por tactical movement + ability area floodfill.
# Plugável: trocar por HexGridSystem mantendo mesma interface.

var size: Vector2i = Vector2i(8, 8)
var cell_size: float = 1.0


func _init(s: Vector2i = Vector2i(8, 8), cs: float = 1.0) -> void:
	size = s
	cell_size = cs


func world_to_cell(world: Vector3) -> Vector2i:
	return Vector2i(floor(world.x / cell_size), floor(world.z / cell_size))


func cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * cell_size + cell_size * 0.5, 0.0, cell.y * cell_size + cell_size * 0.5)


func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < size.x and cell.y >= 0 and cell.y < size.y


func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	var out: Array[Vector2i] = []
	for d in dirs:
		var n: Vector2i = cell + d
		if is_within_bounds(n):
			out.append(n)
	return out


func get_reachable(origin: Vector2i, range_steps: int, walkable: Callable) -> Array[Vector2i]:
	# Floodfill BFS para alcance de movimento / área de magia
	var visited: Dictionary = {origin: true}
	var frontier: Array[Vector2i] = [origin]
	var dist: Dictionary = {origin: 0}
	var result: Array[Vector2i] = []
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		result.append(cur)
		var d: int = dist[cur]
		if d >= range_steps:
			continue
		for n in get_neighbors(cur):
			if visited.has(n):
				continue
			if not walkable.call(n):
				continue
			visited[n] = true
			dist[n] = d + 1
			frontier.append(n)
	return result
