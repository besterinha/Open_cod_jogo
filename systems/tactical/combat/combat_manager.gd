class_name CombatManager
extends Node
# Orquestra combate genérico: custo -> resolver -> aplica efeitos.
# Não trava em hp/armor, usa UnitStats genérico + CombatResolver plugável.

var board: TacticalBoard
var resolver: CombatResolver
var stats_registry: Node # StatsRegistry autoload opcional

signal ability_used(user: Unit, ability: AbilityResource, targets: Array[Vector2i])
signal damage_applied(target: Unit, effects: Array)

func setup(p_board: TacticalBoard, p_resolver: CombatResolver = null) -> void:
	board = p_board
	if p_resolver != null:
		resolver = p_resolver
	else:
		# MVE genérico: hp_only puro (sem Banner Saga) — sem referência a gyms/ (CI bloqueia)
		if ResourceLoader.exists("res://systems/tactical/combat/resolvers/resolver_default.gd"):
			resolver = load("res://systems/tactical/combat/resolvers/resolver_default.gd").new()
		else:
			resolver = CombatResolver.new()

func can_use_ability(user: Unit, ability: AbilityResource, target_cell: Vector2i) -> bool:
	if user.is_defeated():
		return false
	if not user.can_pay(ability.custo):
		return false
	if not board.grid.is_within_bounds(target_cell):
		return false
	var dist: int = abs(user.cell.x - target_cell.x) + abs(user.cell.y - target_cell.y)
	if dist > ability.alcance:
		return false
	return ability.can_activate(user, target_cell)

func get_area_cells(origin: Vector2i, area: String) -> Array[Vector2i]:
	match area:
		"single":
			return [origin]
		"3x3":
			var out: Array[Vector2i] = []
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var c: Vector2i = origin + Vector2i(dx, dy)
					if board.grid.is_within_bounds(c):
						out.append(c)
			return out
		"cross":
			var out: Array[Vector2i] = [origin]
			for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var c: Vector2i = origin + d
				if board.grid.is_within_bounds(c):
					out.append(c)
			return out
		"line":
			# linha de 3 na direção do alvo (simplificado)
			var out: Array[Vector2i] = [origin]
			for i in range(1, 3):
				var c: Vector2i = origin + Vector2i(i, 0)
				if board.grid.is_within_bounds(c):
					out.append(c)
			return out
		_:
			return [origin]

func use_ability(user: Unit, ability: AbilityResource, target_cell: Vector2i) -> bool:
	if not can_use_ability(user, ability, target_cell):
		return false
	# paga custo genérico
	if not user.pay_cost(ability.custo):
		return false
	var area_cells: Array[Vector2i] = get_area_cells(target_cell, ability.area)
	ability_used.emit(user, ability, area_cells)
	# aplica lógica custom da ability se tiver
	ability.activate(user, area_cells)
	# para cada unidade na área, resolve via resolver plugável
	var db: AttributeDatabase = null
	var reg: Node = get_node_or_null("/root/StatsRegistry")
	if reg and reg.has_method("get_db"):
		db = reg.get_db()
	for cell in area_cells:
		var target: Unit = board.get_unit_at(cell)
		if target == null:
			continue
		# permite curar a si mesmo (heal) mas não dano amigo? Para MVE genérico, permite tudo exceto curar inimigo com heal positivo?
		# Simplificado MVE: permite qualquer alvo, resolver decide delta
		if target == user and ability.efeitos.size() > 0 and int(ability.efeitos[0].get("delta", 0)) < 0:
			# não se auto-dane com fireball/strike se mirar em si
			continue
		var result: Dictionary = resolver.resolve(user.stats, target.stats, ability, db)
		var effects: Array = result.get("effects", [])
		for eff in effects:
			var sid: String = str(eff.get("stat_id", ""))
			var delta: int = int(eff.get("delta", 0))
			target.modify_stat(sid, delta)
		damage_applied.emit(target, effects)
		EventBus.combat_resolved.emit(result)
	return true
