class_name Unit
extends Node3D
# Unidade genérica 2.5D — stats 100% data-driven via UnitStats (Dictionary stat_id->int).
# Sem hardcode hp/armor. Visual placeholder swapável.

@export var unit_id: String = ""
@export var team: int = 0 # 0 = player, 1 = enemy
@export var cell: Vector2i = Vector2i.ZERO
@export var stats: UnitStats
@export var display_name: String = "Unit"

signal stats_changed(stat_id: String, new_value: int)
signal unit_defeated(unit: Unit)
signal moved(to_cell: Vector2i)

var _db: AttributeDatabase = null

func _ready() -> void:
	if stats == null:
		stats = UnitStats.new()
	# tenta carregar db para defaults
	var reg: Node = get_node_or_null("/root/StatsRegistry")
	if reg and reg.has_method("get_db"):
		_db = reg.get_db()
		for attr in _db.attributes:
			if not stats.has_stat(attr.id):
				stats.set_stat(attr.id, attr.default_value, _db)
	else:
		# fallback sem db
		if not stats.has_stat("hp"):
			stats.set_stat("hp", 10)
		if not stats.has_stat("movement"):
			stats.set_stat("movement", 4)
	_update_visual()

func get_stat(id: String) -> int:
	return stats.get_stat(id) if stats else 0

func set_stat(id: String, v: int) -> void:
	if stats:
		stats.set_stat(id, v, _db)
		stats_changed.emit(id, v)
		if id == "hp" and v <= 0:
			unit_defeated.emit(self)
		_update_visual()

func modify_stat(id: String, delta: int) -> int:
	if stats == null:
		return 0
	var nxt: int = stats.modify(id, delta, _db)
	stats_changed.emit(id, nxt)
	if id == "hp" and nxt <= 0:
		unit_defeated.emit(self)
	_update_visual()
	return nxt

func is_defeated() -> bool:
	return get_stat("hp") <= 0

func can_pay(cost: Dictionary) -> bool:
	return stats.can_pay(cost) if stats else false

func pay_cost(cost: Dictionary) -> bool:
	if stats == null:
		return false
	var ok: bool = stats.pay(cost, _db)
	if ok:
		for sid in cost.keys():
			stats_changed.emit(str(sid), stats.get_stat(str(sid)))
	return ok

func move_to(new_cell: Vector2i, grid: GridSystem) -> void:
	cell = new_cell
	position = grid.cell_to_world(cell)
	moved.emit(cell)

func _update_visual() -> void:
	# atualiza Label3D se existir (Unit/Label é irmão de Visual, não Visual/Label)
	if has_node("Label"):
		var lbl: Label3D = $Label
		var hp: int = get_stat("hp")
		lbl.text = "%s\nHP:%d" % [display_name, hp]
	elif has_node("Visual/Label"):
		var lbl2: Label3D = $Visual/Label
		var hp2: int = get_stat("hp")
		lbl2.text = "%s\nHP:%d" % [display_name, hp2]
