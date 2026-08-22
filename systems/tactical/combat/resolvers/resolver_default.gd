extends CombatResolver
# Exemplo HP puro — ignora armor, dano direto em hp.

func resolve(_attacker_stats: UnitStats, _defender_stats: UnitStats, ability: AbilityResource, _db: AttributeDatabase) -> Dictionary:
	var dano: int = 0
	for e in ability.efeitos:
		if e is Dictionary and e.get("stat_id") == "hp":
			dano += -int(e.get("delta", 0))
	if dano == 0:
		dano = 5
	return {"effects": [{"stat_id": "hp", "delta": -dano}], "log": "HPOnly: %d dano direto" % dano}
