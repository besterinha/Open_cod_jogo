extends CombatResolver
# Exemplo Shield — shield absorve antes de hp.

func resolve(_attacker_stats: UnitStats, defender_stats: UnitStats, ability: AbilityResource, _db: AttributeDatabase) -> Dictionary:
	var dano: int = 0
	for e in ability.efeitos:
		if e is Dictionary and e.get("stat_id") == "hp":
			dano += -int(e.get("delta", 0))
	if dano == 0:
		dano = 6
	var shield: int = defender_stats.get_stat("shield", 0) if defender_stats else 0
	var effects: Array[Dictionary] = []
	if shield > 0:
		var absorbed: int = min(shield, dano)
		effects.append({"stat_id": "shield", "delta": -absorbed})
		dano -= absorbed
	if dano > 0:
		effects.append({"stat_id": "hp", "delta": -dano})
	return {"effects": effects, "log": "Shield: shield absorveu, hp levou %d" % dano}
