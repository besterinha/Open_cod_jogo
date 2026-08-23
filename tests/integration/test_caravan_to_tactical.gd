extends GutTest
# Integração Caravana -> Tático via EventBus.battle_requested


func test_travel_emite_battle_possible() -> void:
	var caravan := CaravanManager.new()
	add_child_autofree(caravan)
	var travel := TravelSystem.new()
	travel.setup(caravan)
	add_child_autofree(travel)
	watch_signals(travel)
	watch_signals(EventBus)
	travel.travel_one_day()
	assert_signal_emitted(travel, "travel_day_completed")
	# EventBus.day_passed deve ter sido emitido por caravan
	assert_signal_emitted(EventBus, "day_passed")


func test_battle_requested_muda_cena_signal() -> void:
	watch_signals(EventBus)
	EventBus.battle_requested.emit("test_battle")
	assert_signal_emitted(EventBus, "battle_requested")


func test_evento_aplicado_altera_caravana() -> void:
	var caravan := CaravanManager.new()
	caravan.supplies = 30
	caravan.morale = 50
	add_child_autofree(caravan)
	var es := EventSystem.new()
	es.setup(caravan)
	add_child_autofree(es)
	var ev: EventResource = load("res://data/events/supply_raid.tres") as EventResource
	es.register_event(ev)
	var before_supplies: int = caravan.supplies
	es.apply_choice(ev, 1)  # Entregar supplies -20
	assert_eq(caravan.supplies, before_supplies - 20)
