class_name MovementSystem
extends Node
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
	# lógica de célula imediata (para occupancy), animação de posição tween 0.35s
	var start_pos: Vector3 = unit.position
	var end_pos: Vector3 = board.grid.cell_to_world(target)
	unit.cell = target
	# sem árvore (teste unit new() isolado) -> teleporte instantâneo
	if unit.get_tree() == null or not unit.is_inside_tree():
		unit.position = end_pos
		unit.moved.emit(target)
		return true
	# Tween placeholder caminha 0.35s: slide + bob 0.08 + lean 5°
	var tw: Tween = unit.create_tween()
	tw.set_parallel(false)
	tw.tween_property(unit, "position", end_pos, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# bob paralelo (y)
	var y_tw: Tween = unit.create_tween()
	y_tw.set_parallel(false)
	y_tw.tween_property(unit, "position:y", end_pos.y + 0.08, 0.175).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	y_tw.tween_property(unit, "position:y", end_pos.y, 0.175).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# lean Visual 5° na direção
	var vis: Node = unit.get_node_or_null("Visual")
	if vis:
		var dir: float = sign(end_pos.x - start_pos.x)
		if dir == 0:
			dir = sign(end_pos.z - start_pos.z)
		var lean_tw: Tween = unit.create_tween()
		lean_tw.tween_property(vis, "rotation:z", deg_to_rad(5.0 * dir), 0.175).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		lean_tw.tween_property(vis, "rotation:z", 0.0, 0.175).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.finished.connect(func() -> void: unit.moved.emit(target), CONNECT_ONE_SHOT)
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
