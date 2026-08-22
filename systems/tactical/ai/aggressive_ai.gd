extends AIBehavior
# Exemplo plugável: foca unidade inimiga com menor focus_stat_id (ex: hp baixo).

func generate_intent(unit: Unit, board: TacticalBoard) -> Dictionary:
	var enemies: Array[Unit] = []
	for u in board.units:
		if u.team != unit.team and not u.is_defeated():
			enemies.append(u)
	if enemies.is_empty():
		return {}
	# ordena pelo stat alvo
	enemies.sort_custom(func(a: Unit, b: Unit) -> bool:
		return a.get_stat(focus_stat_id) < b.get_stat(focus_stat_id)
	)
	var target: Unit = enemies[0] if prefer_lowest else enemies[-1]
	# tenta mover para perto e atacar
	var dist: int = abs(unit.cell.x - target.cell.x) + abs(unit.cell.y - target.cell.y)
	var reachable: Array[Vector2i] = board.grid.get_reachable(unit.cell, unit.get_stat("movement"), func(c: Vector2i) -> bool: return board.is_walkable(c) or c == unit.cell)
	# escolhe cell mais próxima do alvo dentro do alcance
	var best: Vector2i = unit.cell
	var best_dist: int = dist
	for c in reachable:
		var d: int = abs(c.x - target.cell.x) + abs(c.y - target.cell.y)
		if d < best_dist:
			best_dist = d
			best = c
	return {
		"move_to": best,
		"target": target.cell,
		"target_unit": target
	}
