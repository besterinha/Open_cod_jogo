extends GutTest


func test_fixture_v01_loads() -> void:
	var path: String = "res://tests/fixtures/saves/v0.1.sav"
	assert_true(FileAccess.file_exists(path), "fixture v0.1.sav deve existir")
	var f := FileAccess.open(path, FileAccess.READ)
	var txt: String = f.get_as_text()
	var parsed: Variant = JSON.parse_string(txt)
	assert_not_null(parsed)
	assert_true(parsed is Dictionary)
	var dict: Dictionary = parsed as Dictionary
	assert_eq(int(dict.get("day")), 1, "dia fixture (JSON->int)")
	assert_true(dict.has("supplies"))
	assert_true(dict.has("pop"))


func test_save_round_trip() -> void:
	var save := SaveSystem
	# cria dados de teste
	var data: Dictionary = {
		"day": 5,
		"supplies": 12,
		"morale": 70,
		"renown": 3,
		"pop": {"clansmen": 90, "fighters": 20, "varl": 5}
	}
	save.set_data(data)
	assert_true(save.save(), "save() deve escrever user://save.json")
	assert_true(save.load_save(), "load_save() deve ler de volta")
	var loaded: Dictionary = save.get_data()
	assert_eq(int(loaded["day"]), 5, "dia roundtrip (JSON->int)")
	assert_eq(int(loaded["supplies"]), 12, "supplies roundtrip")
	assert_eq(int(loaded["morale"]), 70, "morale roundtrip")
