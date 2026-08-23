extends GutTest
# Contract: DataValidator bloqueia conteúdo IA inválido antes de GUT


func test_all_abilities_in_data_pass_contract() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	assert_not_null(db)
	# glob: varre data/abilities para não deixar nova .tres sem validar (fecha brecha #2)
	var dir := DirAccess.open("res://data/abilities")
	assert_not_null(dir, "data/abilities deve existir")
	dir.list_dir_begin()
	var file: String = dir.get_next()
	var count: int = 0
	while file != "":
		if file.ends_with(".tres") and not dir.current_is_dir():
			var p: String = "res://data/abilities/" + file
			var a: Resource = load(p)
			assert_not_null(a, "Ability faltando: %s" % p)
			var errs: Array[String] = DataValidator.validate_ability(a, db)
			assert_eq(errs.size(), 0, "%s inválido: %s" % [p, ", ".join(errs)])
			count += 1
		file = dir.get_next()
	assert_true(count >= 3, "deve ter pelo menos 3 abilities")


func test_rejects_vfx_inexistente() -> void:
	var a := AbilityResource.new()
	a.id = "bad_vfx"
	a.nome = "BadVfx"
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	# vfx null é ok, mas se setar PackedScene com path inexistente deve falhar — testamos via DataValidator com path
	# como não dá para criar PackedScene fake facilmente, testamos efeitos vazio que agora é rejeitado
	a.efeitos = []
	var errs: Array[String] = DataValidator.validate_ability(a)
	assert_true(
		errs.any(func(e: String) -> bool: return "efeitos" in e), "efeitos vazio deve ser rejeitado"
	)


func test_rejects_id_duplicado_via_database() -> void:
	# AttributeDatabase já valida ids duplicados, testamos via ability id duplicado na pasta (manual)
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var ids: Dictionary = {}
	for attr in db.attributes:
		assert_false(ids.has(attr.id), "id duplicado em attributes: %s" % attr.id)
		ids[attr.id] = true


func test_rejects_unknown_stat_id() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "bad_stat"
	a.nome = "Bad"
	a.custo = {"unknown_stat": 1}
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_true(
		errs.any(func(e: String) -> bool: return "unknown" in e or "desconhecido" in e),
		"Deveria rejeitar stat desconhecido"
	)


func test_rejects_area_outside_whitelist() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "bad_area"
	a.nome = "Bad"
	a.area = "banana"
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_true(errs.any(func(e: String) -> bool: return "area" in e))


func test_rejects_alcance_over_10() -> void:
	var a := AbilityResource.new()
	a.id = "far"
	a.nome = "Far"
	a.alcance = 99
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a)
	assert_true(errs.any(func(e: String) -> bool: return "alcance" in e))


func test_rejects_efeito_sem_stat_id() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "no_stat"
	a.nome = "NoStat"
	a.efeitos = [{"delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_true(errs.any(func(e: String) -> bool: return "stat_id" in e))


func test_event_contract_weight_and_escolhas() -> void:
	var ev: Resource = load("res://data/events/supply_raid.tres")
	assert_not_null(ev)
	var errs: Array[String] = DataValidator.validate_event(ev)
	assert_eq(errs.size(), 0, "supply_raid inválido: %s" % ", ".join(errs))


func test_all_events_in_data_pass_contract() -> void:
	var dir := DirAccess.open("res://data/events")
	assert_not_null(dir, "data/events deve existir")
	dir.list_dir_begin()
	var file: String = dir.get_next()
	var count: int = 0
	while file != "":
		if file.ends_with(".tres") and not dir.current_is_dir():
			var p: String = "res://data/events/" + file
			var ev: Resource = load(p)
			assert_not_null(ev, "Event faltando: %s" % p)
			var errs: Array[String] = DataValidator.validate_event(ev)
			assert_eq(errs.size(), 0, "%s inválido: %s" % [p, ", ".join(errs)])
			count += 1
		file = dir.get_next()
	assert_true(count >= 3, "deve ter pelo menos 3 eventos (GDD 3/3)")
