extends Node
# EventBus — Autoload global para desacoplar sistemas.
# systems emitem aqui, ui/content escutam. Nunca systems dependem de content.

# Caravana
signal day_passed(day: int)
signal supplies_changed(value: int)
signal morale_changed(value: int, state: String)
signal renown_changed(value: int)
signal caravan_updated(pop: Dictionary)

# Tático
signal ability_activated(ability_id: String, user: Node, targets: Array)
signal combat_resolved(result: Dictionary)
signal turn_changed(unit: Node)

# Geral
signal event_triggered(event_id: String)
signal battle_requested(map_id: String)
