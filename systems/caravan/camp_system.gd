class_name CampSystem
extends Node
# Plugável: descanso, cura, perde supplies.

var caravan: CaravanManager

signal rested(day: int)
signal camp_not_possible(reason: String)

func setup(p_caravan: CaravanManager) -> void:
	caravan = p_caravan

func can_rest() -> bool:
	return caravan != null and caravan.supplies > 0

func rest(days: int = 1) -> bool:
	if not can_rest():
		camp_not_possible.emit("Sem supplies para acampar")
		return false
	for i in days:
		if caravan.supplies <= 0:
			camp_not_possible.emit("Supplies esgotados")
			break
		caravan.rest_day()
		rested.emit(caravan.day)
		# cura heróis via EventBus (futuro: hero system escuta)
		EventBus.morale_changed.emit(caravan.morale, caravan.get_morale_state())
	return true

func force_rest(days: int = 1) -> void:
	# mesmo sem supplies, descansa (sem recuperar morale)
	for i in days:
		caravan.day += 1
		caravan.morale = max(0, caravan.morale - 5)
		EventBus.day_passed.emit(caravan.day)
		EventBus.morale_changed.emit(caravan.morale, caravan.get_morale_state())
