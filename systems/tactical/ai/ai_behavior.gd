extends Resource
class_name AIBehavior
# Interface plugável genérica — stat_id configurável, não trava em hp.

@export var focus_stat_id: String = "hp" # qual stat focar quando baixo = alvo fraco
@export var prefer_lowest: bool = true

func generate_intent(unit: Unit, board: TacticalBoard) -> Dictionary:
	# Retorna {"move_to": Vector2i, "ability": AbilityResource, "target": Vector2i} ou {}
	push_warning("AIBehavior base chamado")
	return {}
