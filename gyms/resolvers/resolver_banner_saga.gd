extends CombatResolver
# Exemplo Banner Saga-like — NÃO é contrato. Só prova que resolver é plugável.
# Fórmula: dano = max(0, base_dano - armor_defensor)
# base_dano vem de ability.efeitos[0].delta (negativo = dano)

func resolve(attacker_stats: UnitStats, defender_stats: UnitStats, ability: AbilityResource, db: AttributeDatabase) -> Dictionary:
	var base_dano: int = 0
	for e in ability.efeitos:
		if e is Dictionary and e.get("stat_id") == "hp" and int(e.get("delta", 0)) < 0:
			base_dano = -int(e.get("delta", 0))
			break
	if base_dano == 0:
		base_dano = 5 # fallback exemplo
	var armor: int = defender_stats.get_stat("armor", 0) if defender_stats else 0
	var dano_final: int = max(0, base_dano - armor)
	var effects: Array[Dictionary] = [{"stat_id": "hp", "delta": -dano_final}]
	if dano_final > 0 and armor > 0:
		# também reduz armor em 1 (exemplo Banner Saga: armor break)
		effects.append({"stat_id": "armor", "delta": -1})
	return {"effects": effects, "log": "BannerSaga: %d - %d armor = %d dano" % [base_dano, armor, dano_final]}
