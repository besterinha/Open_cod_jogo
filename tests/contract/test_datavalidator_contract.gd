extends GutTest
# Contract: DataValidator bloqueia conteúdo IA inválido antes de GUT

func test_all_abilities_in_data_pass_contract() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	assert_not_null(db)
	var paths: Array[String] = ["res://data/abilities/strike.tres", "res://data/abilities/heal.tres", "res://data/abilities/fireball.tres"]
	for p in paths:
		var a: Resource = load(p)
		assert_not_null(a, "Ability faltando: %s" % p)
		var errs: Array[String] = DataValidator.validate_ability(a, db)
		assert_eq(errs.size(), 0, "%s inválido: %s" % [p, ", ".join(errs)])

func test_rejects_unknown_stat_id() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "bad_stat"
	a.nome = "Bad"
	a.custo = {"unknown_stat": 1}
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_true(errs.any(func(e: String) -> bool: return "unknown" in e or "desconhecido" in e), "Deveria rejeitar stat desconhecido")

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
