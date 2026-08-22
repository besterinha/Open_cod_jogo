class_name TravelSystem
extends Node
# Plugável: consome dias, emite sinais, gerencia velocidade/terreno.
# Usa CaravanManager para aplicar custo.

var caravan: CaravanManager
var days_traveled: int = 0
var is_traveling: bool = false
var travel_speed: float = 1.0 # dias por segundo (debug)

signal travel_started(days: int)
signal travel_day_completed(day: int)
signal travel_finished(total_days: int)

func setup(p_caravan: CaravanManager) -> void:
	caravan = p_caravan

func travel(days: int) -> void:
	if caravan == null:
		push_error("TravelSystem: caravan não setado")
		return
	is_traveling = true
	travel_started.emit(days)
	for i in days:
		if caravan.supplies <= 0 and caravan.morale <= 0:
			break # caravana colapsada
		caravan.consume_day()
		days_traveled += 1
		travel_day_completed.emit(caravan.day)
		EventBus.day_passed.emit(caravan.day)
		# chance de evento random (delegado para EventSystem externo)
		EventBus.event_triggered.emit("check_random")
	is_traveling = false
	travel_finished.emit(days)

func travel_one_day() -> void:
	travel(1)
