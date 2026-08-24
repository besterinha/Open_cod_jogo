class_name MovementSystem
extends Node
# Sistema genérico: floodfill para alcance + A* para caminho.
# Lock anti-stack: 1 tween por unidade — move_unit rejeita enquanto anima (bug multi-tap).

var board: TacticalBoard
var _active: Dictionary = {}  # unit instance_id -> Tween


func setup(p_board: TacticalBoard) -> void:
	board = p_board


func is_moving(unit: Unit) -> bool:
	var id: int = unit.get_instance_id()
	if not _active.has(id):
		return false
	var tw: Tween = _active[id] as Tween
	if tw == null or not tw.is_valid() or not tw.is_running():
		_active.erase(id)
		return false
	return true


func get_reachable(unit: Unit) -> Array[Vector2i]:
	# Alcance de movimento por ORÇAMENTO DE CUSTO (terreno custoso), não por passos.
	var budget: int = unit.get_stat("movement")
	return _reachable_with_cost(unit.cell, budget)


func _reachable_with_cost(origin: Vector2i, budget: int) -> Array[Vector2i]:
	# Dijkstra-lite 4-dir: acumula move_cost do terreno; blocked é intransponível.
	var cost: Dictionary = {origin: 0}
	var frontier: Array[Vector2i] = [origin]
	var result: Array[Vector2i] = [origin]
	while not frontier.is_empty():
		frontier.sort_custom(
			func(a: Vector2i, b: Vector2i) -> bool: return cost.get(a, 9999) < cost.get(b, 9999)
		)
		var cur: Vector2i = frontier.pop_front()
		for n in board.grid.get_neighbors(cur):
			if not board.is_walkable(n):
				continue
			var step: int = board.terrain.move_cost(n) if board.terrain != null else 1
			var nc: int = int(cost[cur]) + step
			if nc > budget:
				continue
			if cost.has(n) and int(cost[n]) <= nc:
				continue
			cost[n] = nc
			if not result.has(n):
				result.append(n)
			if not frontier.has(n):
				frontier.append(n)
	return result


func can_move_to(unit: Unit, target: Vector2i) -> bool:
	return get_reachable(unit).has(target)


func move_unit(unit: Unit, target: Vector2i) -> bool:
	if is_moving(unit):
		return false  # lock anti-stack: nunca 2 tweens na mesma unidade (aceleração/diagonal)
	if not can_move_to(unit, target):
		return false
	var old: Vector2i = unit.cell
	var path: Array[Vector2i] = find_path(unit.cell, target)
	if path.is_empty():
		return false
	board.update_occupancy(unit, old, target)
	# piso de dano: aplica delta uma vez ao entrar (consumidor Unit.stats)
	if board.terrain != null:
		board.terrain.on_unit_entered(unit, target)
	# ocupação imediata (consumidor board), animação tween 0.70 per-cell + 4-dir waypoints
	var path_world: Array[Vector3] = []
	for c in path:
		path_world.append(board.grid.cell_to_world(c))
	unit.cell = target
	if unit.get_tree() == null or not unit.is_inside_tree():
		unit.position = path_world[-1]
		unit.moved.emit(target)
		return true
	const SEC_PER_CELL: float = 0.70
	var id: int = unit.get_instance_id()
	var tw: Tween = unit.create_tween()
	tw.set_parallel(false)
	# 4-dir waypoints: slide sequencial por célula (não linha reta diagonal) + bob y no mesmo tween
	for i in range(1, path_world.size()):
		var nxt: Vector3 = path_world[i]
		var base_y: float = nxt.y
		tw.tween_property(unit, "position", nxt, SEC_PER_CELL).set_trans(Tween.TRANS_SINE).set_ease(
			Tween.EASE_IN_OUT
		)
		tw.parallel().tween_method(
			func(p: float) -> void: unit.position.y = base_y + sin(p * PI) * 0.08,
			0.0,
			1.0,
			SEC_PER_CELL
		)
	tw.finished.connect(
		func() -> void:
			_active.erase(id)
			unit.moved.emit(target),
		CONNECT_ONE_SHOT
	)
	_active[id] = tw
	return true


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# A* Manhattan ponderado pelo custo de terreno (blocked intransponível)
	if from == to:
		return [from]
	var open: Array[Vector2i] = [from]
	var came_from: Dictionary = {}
	var g_score: Dictionary = {from: 0}
	var f_score: Dictionary = {from: _heuristic(from, to)}
	var closed: Dictionary = {}
	while not open.is_empty():
		open.sort_custom(
			func(a: Vector2i, b: Vector2i) -> bool:
				return f_score.get(a, 9999) < f_score.get(b, 9999)
		)
		var cur: Vector2i = open.pop_front()
		if cur == to:
			return _reconstruct(came_from, cur)
		closed[cur] = true
		for n in board.grid.get_neighbors(cur):
			if closed.has(n):
				continue
			if not board.is_walkable(n) and n != to:
				continue
			var step_cost: int = board.terrain.move_cost(n) if board.terrain != null else 1
			var tentative: int = int(g_score[cur]) + step_cost
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
