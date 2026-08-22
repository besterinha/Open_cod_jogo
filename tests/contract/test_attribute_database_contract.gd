extends GutTest

func test_database_valid() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	assert_not_null(db)
	var errs: Array[String] = db.validate()
	assert_eq(errs.size(), 0, "attributes.tres inválido: %s" % ", ".join(errs))

func test_ids_unique() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var seen: Dictionary = {}
	for attr in db.attributes:
		assert_false(seen.has(attr.id), "id duplicado: %s" % attr.id)
		seen[attr.id] = true

func test_clamp_respects_min_max() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var hp_def: AttributeDefinition = db.get_def("hp")
	assert_not_null(hp_def)
	assert_eq(db.clamp_value("hp", 9999), hp_def.max_value)
	assert_eq(db.clamp_value("hp", -999), hp_def.min_value)

func test_unit_stats_rejects_unknown_stat() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var s := UnitStats.new()
	s.set_stat("hp", 10)
	s.set_stat("banana", 5)
	var errs: Array[String] = s.validate_against(db)
	assert_true(errs.size() > 0)
	assert_true(errs[0].contains("banana"))
