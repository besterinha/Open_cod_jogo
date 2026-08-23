extends GutTest
# Testa motor genérico de stats — prova que não está travado em Banner Saga.


func test_attribute_database_valid() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	assert_not_null(db)
	var errs: Array[String] = db.validate()
	assert_eq(errs.size(), 0, "attributes.tres inválido: %s" % ", ".join(errs))


func test_unit_stats_can_pay_genérico() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var s := UnitStats.new()
	s.set_stat("willpower", 3, db)
	s.set_stat("hp", 10, db)
	assert_true(s.can_pay({"willpower": 2}))
	assert_false(s.can_pay({"willpower": 5}))
	assert_false(s.can_pay({"mana": 1}), "mana não existe no db default")


func test_ability_validator_custo_stat_id_genérico() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "test"
	a.nome = "Teste Genérico"
	a.custo = {"willpower": 2}
	a.alcance = 1
	a.area = "single"
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_eq(errs.size(), 0, "Ability genérica válida não deve falhar: %s" % ", ".join(errs))


func test_ability_validator_rejeita_stat_desconhecido() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a := AbilityResource.new()
	a.id = "bad"
	a.nome = "Bad"
	a.custo = {"banana": 1}
	a.efeitos = [{"stat_id": "xyz", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_true(errs.size() >= 2, "Deveria rejeitar stat_id desconhecido")


func test_resolver_banner_saga_vs_hp_only_diferentes() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var atk := UnitStats.new()
	atk.set_stat("hp", 10, db)
	var def := UnitStats.new()
	def.set_stat("hp", 10, db)
	def.set_stat("armor", 3, db)
	var abil := AbilityResource.new()
	abil.efeitos = [{"stat_id": "hp", "delta": -6}]
	var r_banner: CombatResolver = load("res://gyms/resolvers/resolver_banner_saga.gd").new()
	var r_hp: CombatResolver = load("res://gyms/resolvers/resolver_hp_only.gd").new()
	var res_banner: Dictionary = r_banner.resolve(atk, def, abil, db)
	var res_hp: Dictionary = r_hp.resolve(atk, def, abil, db)
	# banner: 6-3 armor = 3 dano; hp_only: 6 dano
	var dmg_banner: int = 0
	for e in res_banner["effects"]:
		if e["stat_id"] == "hp":
			dmg_banner = -int(e["delta"])
	var dmg_hp: int = 0
	for e in res_hp["effects"]:
		if e["stat_id"] == "hp":
			dmg_hp = -int(e["delta"])
	assert_eq(dmg_banner, 3, "Banner Saga deve reduzir por armor")
	assert_eq(dmg_hp, 6, "HP only deve ignorar armor")
	assert_ne(dmg_banner, dmg_hp, "Resolvers devem ser diferentes — prova genericidade")


func test_shield_resolver_absorve() -> void:
	var db := AttributeDatabase.new()
	# cria shield temporário para teste
	var shield_def := AttributeDefinition.new()
	shield_def.id = "shield"
	shield_def.nome = "Escudo"
	shield_def.default_value = 5
	shield_def.min_value = 0
	shield_def.max_value = 20
	var hp_def := AttributeDefinition.new()
	hp_def.id = "hp"
	hp_def.nome = "Vida"
	hp_def.default_value = 10
	db.attributes = [shield_def, hp_def]
	var atk := UnitStats.new()
	var def := UnitStats.new()
	def.set_stat("shield", 4, db)
	def.set_stat("hp", 10, db)
	var abil := AbilityResource.new()
	abil.efeitos = [{"stat_id": "hp", "delta": -6}]
	var r: CombatResolver = load("res://gyms/resolvers/resolver_shield.gd").new()
	var res: Dictionary = r.resolve(atk, def, abil, db)
	# shield 4 absorve, restam 2 em hp
	var shield_delta: int = 0
	var hp_delta: int = 0
	for e in res["effects"]:
		if e["stat_id"] == "shield":
			shield_delta = int(e["delta"])
		if e["stat_id"] == "hp":
			hp_delta = int(e["delta"])
	assert_eq(shield_delta, -4)
	assert_eq(hp_delta, -2)
