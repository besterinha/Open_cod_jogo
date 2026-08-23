extends GutTest
# Valida contrato de AbilityResource — garante que IA não gera magia quebrada.

func test_valid_ability_passes() -> void:
	var a := AbilityResource.new()
	a.id = "test"
	a.nome = "Teste"
	a.alcance = 3
	a.area = "single"
	a.efeitos = [{"stat_id": "hp", "delta": -5}]
	var errs: Array[String] = DataValidator.validate_ability(a)
	assert_eq(errs.size(), 0, "Ability válida não deve ter erros: %s" % ", ".join(errs))

func test_empty_id_fails() -> void:
	var a := AbilityResource.new()
	a.id = ""
	a.nome = "Sem ID"
	var errs: Array[String] = DataValidator.validate_ability(a)
	assert_true(errs.size() > 0)
	assert_true(errs.any(func(e: String) -> bool: return "id" in e))

func test_invalid_area_fails() -> void:
	var a := AbilityResource.new()
	a.id = "x"
	a.nome = "X"
	a.area = "banana"
	var errs: Array[String] = DataValidator.validate_ability(a)
	assert_true(errs.any(func(e: String) -> bool: return "area" in e))

func test_fireball_fixture_valid() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var a: Resource = load("res://data/abilities/fireball.tres")
	var errs: Array[String] = DataValidator.validate_ability(a, db)
	assert_eq(errs.size(), 0, "fireball.tres inválido: %s" % ", ".join(errs))
