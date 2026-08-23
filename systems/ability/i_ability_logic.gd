class_name IAbilityLogic
extends Resource
# Interface Strategy para lógica de habilidade.
# Implemente em GDScript plugável e referencie em AbilityResource.logic_script.
# Exemplo: res://systems/ability/logics/area_damage.gd


func can_activate(_user: Node, _target_cell: Vector2i, _ability: AbilityResource) -> bool:
	return true


func activate(_user: Node, _target_cells: Array[Vector2i], _ability: AbilityResource) -> void:
	pass
