extends Resource
class_name AbilityResource
# Resource plugável para qualquer habilidade/magia/ação.
# Toda magia é um .tres que referencia logic_script (Strategy) + vfx placeholder.
# IA gera .tres, nunca edita systems/.

@export var id: String = ""
@export var nome: String = ""
@export var custo: Dictionary = {"willpower": 1, "renown": 0}
@export var alcance: int = 1
@export var area: String = "single" # single, 3x3, cross, line — validado por DataValidator
@export var efeitos: Array[Resource] = [] # DamageEffect, HealEffect, etc (futuro)
@export var tags_required: PackedStringArray = []
@export var vfx: PackedScene
@export var logic_script: GDScript # deve implementar IAbilityLogic interface

func can_activate(user: Node, target_cell: Vector2i) -> bool:
	if logic_script == null:
		return true # sem lógica custom = sempre pode (MVP)
	var logic = logic_script.new()
	if logic.has_method("can_activate"):
		return logic.can_activate(user, target_cell, self)
	return true

func activate(user: Node, target_cells: Array[Vector2i]) -> void:
	if logic_script == null:
		return
	var logic = logic_script.new()
	if logic.has_method("activate"):
		logic.activate(user, target_cells, self)
