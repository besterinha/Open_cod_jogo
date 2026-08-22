extends Node
class_name MovementSystem
# Sistema genérico: floodfill para alcance + A* para caminho.

var board: TacticalBoard

func setup(p_board: TacticalBoard) -> void:
	board = p_board

func get_reachable(unit: Unit) -> Array[Vector2i]:
	var mov: int = unit.get_stat("movement")
	return board.grid.get_reachable(unit.cell, mov, func(c: Vector2i) -> bool: return board.is_walkable(c) or c == unit.cell)

func can_move_to(unit: Unit, target: Vector2i) -> bool:
	return get_reachable(unit).has(target)

func move_unit(unit: Unit, target: Vector2i) -> bool:
	if not can_move_to(unit, target):
		return false
	var old: Vector2i = unit.cell
	var path: Array[Vector2i] = find_path(unit.cell, target)
	if path.is_empty():
		return false
	board.update_occupancy(unit, old, target)
	unit.move_to(target, board.grid)
	return true

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# A* simples Manhattan
	if from == to:
		return [from]
	var open: Array[Vector2i] = [from]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0}
	var f_score: Dictionary = {from: _heuristic(from, to)}
	var closed: Dictionary = {}
	while not open.is_empty():
		open.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return f_score.get(a, 9999) < f_score.get(b, 9999))
		var cur: Vector2i = open.pop_front()
		if cur == to:
			return _reconstruct(came_from, cur)
		closed[cur] = true
		for n in board.grid.get_neighbors(cur):
			if closed.has(n):
				continue
			if not board.is_walkable(n) and n != to:
				continue
			var tentative: int = g_score[cur] + 1
			if tentative < g_score.get(n, 9999):
				came_from[n] = cur
				g_score[n] = tentative
				f_score[n] = tentative + _heuristic(n, to)
				if not open.has(n):
					open.append(n)
	return []

func _heuristic(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _reconstruct(came_from: Dictionary, cur: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [cur]
	while came_from.has(cur):
		cur = came_from[cur]
		path.push_front(cur)
	return path
