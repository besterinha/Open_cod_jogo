extends IAbilityLogic
# Lógica plugável exemplo: dano em área.
# Referenciado por data/abilities/*.tres


func activate(user: Node, target_cells: Array[Vector2i], ability: AbilityResource) -> void:
	# MVP: loga ativação, futuro aplicará DamageEffect em cada cell
	print(
		(
			"[Ability] %s ativada por %s em %s"
			% [ability.nome, user.name if user else "?", target_cells]
		)
	)
	EventBus.ability_activated.emit(ability.id, user, target_cells)
