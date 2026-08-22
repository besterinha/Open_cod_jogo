extends Resource
class_name CombatResolver
# Interface base plugável — você implementa a fórmula que quiser em GDScript
# e registra via Registry. Motor não trava em Banner Saga.
# Exemplos concretos em gyms/resolvers/.

func resolve(attacker_stats: UnitStats, defender_stats: UnitStats, ability: AbilityResource, db: AttributeDatabase) -> Dictionary:
	# Retorna {"effects": Array[Dictionary], "log": String}
	# Efeitos são genéricos: [{"stat_id": "hp", "delta": -5}, ...]
	push_warning("CombatResolver base chamado — sobrescreva em resolver plugável")
	return {"effects": [], "log": "base resolver — sem efeito"}
