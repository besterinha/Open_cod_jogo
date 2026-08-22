extends Node
# StatsRegistry — Autoload opcional (ou usado via preload).
# Carrega AttributeDatabase de data/stats/ e valida tudo.
# Se nenhum arquivo existir, cria defaults Banner Saga-like como exemplo.

const DEFAULT_STATS_PATH := "res://data/stats/attributes.tres"

var _db: AttributeDatabase = null

func get_db() -> AttributeDatabase:
	if _db != null:
		return _db
	if ResourceLoader.exists(DEFAULT_STATS_PATH):
		var res: Resource = load(DEFAULT_STATS_PATH)
		if res is AttributeDatabase:
			_db = res
			return _db
	# fallback: cria defaults em memória (não salva), para não travar editor sem data/
	_db = _create_fallback()
	return _db

func _create_fallback() -> AttributeDatabase:
	var db := AttributeDatabase.new()
	var hp := AttributeDefinition.new()
	hp.id = "hp"; hp.nome = "Vida"; hp.default_value = 10; hp.min_value = 0; hp.max_value = 99
	var armor := AttributeDefinition.new()
	armor.id = "armor"; armor.nome = "Armadura"; armor.default_value = 5; armor.min_value = 0; armor.max_value = 20
	var will := AttributeDefinition.new()
	will.id = "willpower"; will.nome = "Vontade"; will.default_value = 3; will.min_value = 0; will.max_value = 10; will.is_resource = true
	var mov := AttributeDefinition.new()
	mov.id = "movement"; mov.nome = "Movimento"; mov.default_value = 4; mov.min_value = 1; mov.max_value = 10
	db.attributes = [hp, armor, will, mov]
	return db

func is_valid_stat(id: String) -> bool:
	return get_db().is_valid_id(id)

func reload() -> void:
	_db = null
