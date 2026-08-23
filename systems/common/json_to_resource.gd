class_name JsonToResource
extends RefCounted
# Conversor JSON -> Resource para IA (TDD.md #schema-ia)
# IA gera JSON, este stub valida contra AttributeDatabase e cria AbilityResource .tres
# Justificativa A3: TDD promete este arquivo para IA não tocar em systems/; bootstrap criou data/*.tres direto,
# mas IA precisa do conversor. Stub mantém arquitetura (content -> systems) e fecha A3 sem criar código morto.

static func json_to_ability(json: Dictionary, db: AttributeDatabase = null) -> AbilityResource:
	if db == null:
		db = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = str(json.get("id", ""))
	a.nome = str(json.get("nome", a.id))
	# custo genérico {stat_id: valor}
	var custo_raw: Variant = json.get("custo", {})
	if custo_raw is Dictionary:
		a.custo = custo_raw as Dictionary
	else:
		a.custo = {}
	a.alcance = int(json.get("alcance", 1))
	a.area = str(json.get("area", "single"))
	var efeitos_raw: Variant = json.get("efeitos", [])
	if efeitos_raw is Array:
		a.efeitos = efeitos_raw as Array
	else:
		a.efeitos = []
	var vfx_path: String = str(json.get("vfx", ""))
	if vfx_path != "" and ResourceLoader.exists(vfx_path):
		a.vfx = load(vfx_path) as PackedScene
	var logic_path: String = str(json.get("logic_script", ""))
	if logic_path != "" and ResourceLoader.exists(logic_path):
		a.logic_script = load(logic_path) as GDScript
	# valida antes de retornar; quem chama deve checar DataValidator
	return a

static func validate_and_convert(json: Dictionary, db: AttributeDatabase = null) -> Dictionary:
	# retorna {ability: AbilityResource, errors: Array[String]}
	if db == null:
		db = load("res://data/stats/attributes.tres") as AttributeDatabase
	var abil: AbilityResource = json_to_ability(json, db)
	var errs: Array[String] = DataValidator.validate_ability(abil, db)
	return {"ability": abil, "errors": errs}
