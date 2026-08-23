class_name UnitStats
extends Resource
# Mapa genérico stat_id -> valor, validado contra AttributeDatabase.
# Cada unidade (Node) terá um UnitStats instance.

@export var values: Dictionary = {}  # {stat_id: int}


func get_stat(id: String, default: int = 0) -> int:
	return int(values.get(id, default))


func set_stat(id: String, v: int, db: AttributeDatabase = null) -> void:
	if db != null:
		v = db.clamp_value(id, v)
	values[id] = v


func has_stat(id: String) -> bool:
	return values.has(id)


func modify(id: String, delta: int, db: AttributeDatabase = null) -> int:
	var cur: int = get_stat(id)
	var nxt: int = cur + delta
	if db != null:
		nxt = db.clamp_value(id, nxt)
	values[id] = nxt
	return nxt


func can_pay(cost: Dictionary) -> bool:
	for stat_id in cost.keys():
		if get_stat(stat_id) < int(cost[stat_id]):
			return false
	return true


func pay(cost: Dictionary, db: AttributeDatabase = null) -> bool:
	if not can_pay(cost):
		return false
	for stat_id in cost.keys():
		modify(stat_id, -int(cost[stat_id]), db)
	return true


func apply_effects(effects: Array[Dictionary], db: AttributeDatabase = null) -> void:
	# effects: [{"stat_id": "hp", "delta": -5}, ...]
	for e in effects:
		var sid: String = str(e.get("stat_id", ""))
		var delta: int = int(e.get("delta", 0))
		if sid.is_empty():
			continue
		modify(sid, delta, db)


func validate_against(db: AttributeDatabase) -> Array[String]:
	var errs: Array[String] = []
	if db == null:
		return errs
	for sid in values.keys():
		if not db.is_valid_id(sid):
			errs.append("stat_id desconhecido: %s" % sid)
	return errs


func to_dict() -> Dictionary:
	return values.duplicate(true)


static func from_dict(d: Dictionary) -> UnitStats:
	var s := UnitStats.new()
	s.values = d.duplicate(true)
	return s
