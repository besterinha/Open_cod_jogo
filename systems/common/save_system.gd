extends Node
# SaveSystem — Autoload para persistência JSON (plaintext debug, depois binary).
# Guarda fixtures em tests/fixtures/saves/ para teste de compatibilidade.

const SAVE_PATH := "user://save.json"

var _data: Dictionary = {
	"day": 1,
	"supplies": 30,
	"morale": 50,
	"renown": 0,
	"pop": {"clansmen": 100, "fighters": 30, "varl": 10, "heroes": []},
}


func get_data() -> Dictionary:
	return _data.duplicate(true)


func set_data(d: Dictionary) -> void:
	_data = d.duplicate(true)


func save() -> bool:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		push_error("SaveSystem: falha ao abrir %s" % SAVE_PATH)
		return false
	f.store_string(JSON.stringify(_data, "\t"))
	return true


func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var txt := f.get_as_text()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: JSON inválido")
		return false
	_data = parsed
	return true
