extends Control
# HUD tático touch — 3 habilidades plugáveis + Passar Turno.
# Gera botões dinamicamente de data/abilities/*.tres, valida custo genérico.

signal ability_selected(ability: AbilityResource)
signal end_turn_pressed

@onready var hbox: HBoxContainer = $HBox
@onready var end_btn: Button = $HBox/EndTurn

var _abilities: Array[AbilityResource] = []
var _selected: AbilityResource = null
var _current_unit: Unit = null


func _ready() -> void:
	end_btn.pressed.connect(func() -> void: end_turn_pressed.emit())
	_load_abilities()
	# escuta turno para atualizar disabled por custo
	EventBus.turn_changed.connect(_on_turn_changed)


const BASE_ABILITY_PATHS: Array[String] = [
	# export-safe: listagem de diretório NÃO existe no pacote — toda habilidade
	# que deve aparecer no device precisa estar nesta lista (TDD §4e)
	"res://data/abilities/strike.tres",
	"res://data/abilities/heal.tres",
	"res://data/abilities/fireball.tres",
	"res://data/abilities/conejato.tres",
	"res://data/abilities/anelado.tres",
]


func _load_abilities() -> void:
	# limpa antigos (mantém EndTurn)
	for child in hbox.get_children():
		if child != end_btn and child is Button:
			child.queue_free()
	_abilities.clear()
	var loaded_ids: Dictionary = {}
	# 1) lista export-safe (funciona dentro do APK)
	for p in BASE_ABILITY_PATHS:
		if ResourceLoader.exists(p):
			var a: Resource = load(p)
			if a is AbilityResource:
				_add_ability(a as AbilityResource)
				loaded_ids[(a as AbilityResource).id] = true
	# 2) glob extra apenas onde disponível (editor/dev) — export-safe: evita duplicar
	var dir := DirAccess.open("res://data/abilities/")  # export-safe: complementar à lista acima
	if dir != null:
		dir.list_dir_begin()
		var file: String = dir.get_next()
		while file != "":
			if file.ends_with(".tres") and not dir.current_is_dir():
				var a: Resource = load("res://data/abilities/" + file)
				if a is AbilityResource and not loaded_ids.has((a as AbilityResource).id):
					_add_ability(a as AbilityResource)
					loaded_ids[(a as AbilityResource).id] = true
			file = dir.get_next()
		dir.list_dir_end()
	_update_selection()


func _add_ability(abil: AbilityResource) -> void:
	_abilities.append(abil)
	_create_button(abil)


func _create_button(abil: AbilityResource) -> void:
	var btn := Button.new()
	btn.name = abil.id
	btn.custom_minimum_size = Vector2(110, 60)
	btn.text = "%s\n(%d)" % [abil.nome, abil.custo.values()[0] if not abil.custo.is_empty() else 0]
	# mostra custo genérico: ex "2 willpower"
	if not abil.custo.is_empty():
		var cost_str: String = ""
		for k in abil.custo.keys():
			cost_str += "%s:%d " % [k, abil.custo[k]]
		btn.text = "%s\n%s" % [abil.nome, cost_str.strip_edges()]
		btn.tooltip_text = "Alc %d Area %s" % [abil.alcance, abil.area]
	else:
		btn.tooltip_text = "Alc %d Area %s" % [abil.alcance, abil.area]
	btn.pressed.connect(func() -> void: _on_ability_pressed(abil, btn))
	hbox.add_child(btn)
	hbox.move_child(btn, hbox.get_child_count() - 2)  # antes do EndTurn


func _on_ability_pressed(abil: AbilityResource, btn: Button) -> void:
	_selected = abil
	ability_selected.emit(abil)
	# destaca seleção
	for child in hbox.get_children():
		if child is Button and child != end_btn:
			child.modulate = Color(1, 1, 1)
	btn.modulate = Color(1, 0.9, 0.4)
	print("[HUD] Selecionada %s" % abil.nome)
	_update_buttons()


func _on_turn_changed(unit: Unit) -> void:
	_current_unit = unit
	_update_buttons()
	# auto-seleciona primeira habilidade se nenhuma
	if _selected == null and not _abilities.is_empty():
		_selected = _abilities[0]
		ability_selected.emit(_selected)


func _update_buttons() -> void:
	if _current_unit == null:
		return
	for child in hbox.get_children():
		if child is Button and child != end_btn:
			var abil: AbilityResource = null
			for a in _abilities:
				if a.id == child.name:
					abil = a
					break
			if abil:
				var can: bool = _current_unit.can_pay(abil.custo)
				child.disabled = not can
				child.modulate.a = 1.0 if can else 0.5


func _update_selection() -> void:
	if not _abilities.is_empty() and _selected == null:
		_selected = _abilities[0]


func get_selected() -> AbilityResource:
	return _selected
