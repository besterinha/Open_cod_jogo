extends GutTest
# Testa Motor Caravana Fase 1: Travel, Camp, Market, Event — genérico, validável.


func test_travel_one_day_consumes() -> void:
	var c := CaravanManager.new()
	c.supplies = 10
	c.morale = 50
	var t := TravelSystem.new()
	t.setup(c)
	add_child_autofree(t)
	add_child_autofree(c)
	t.travel_one_day()
	assert_eq(c.supplies, 9)
	assert_eq(c.day, 2)


func test_camp_rest_recovers_morale() -> void:
	var c := CaravanManager.new()
	c.supplies = 10
	c.morale = 40
	var camp := CampSystem.new()
	camp.setup(c)
	add_child_autofree(camp)
	add_child_autofree(c)
	camp.rest(1)
	assert_eq(c.morale, 50)
	assert_eq(c.supplies, 9)


func test_camp_no_supplies_fails() -> void:
	var c := CaravanManager.new()
	c.supplies = 0
	var camp := CampSystem.new()
	camp.setup(c)
	add_child_autofree(camp)
	add_child_autofree(c)
	assert_false(camp.can_rest())
	assert_false(camp.rest(1))


func test_market_buy_supplies() -> void:
	var c := CaravanManager.new()
	c.renown = 5
	c.supplies = 0
	var m := MarketSystem.new()
	m.setup(c)
	m.current_rate = 5
	add_child_autofree(m)
	add_child_autofree(c)
	assert_true(m.buy_supplies(1))
	assert_eq(c.supplies, 5)
	assert_eq(c.renown, 4)


func test_market_insufficient_renown_fails() -> void:
	var c := CaravanManager.new()
	c.renown = 0
	var m := MarketSystem.new()
	m.setup(c)
	add_child_autofree(m)
	add_child_autofree(c)
	assert_false(m.buy_supplies(1))


func test_event_roll_and_apply() -> void:
	var c := CaravanManager.new()
	c.supplies = 30
	c.morale = 50
	var es := EventSystem.new()
	es.setup(c)
	add_child_autofree(es)
	add_child_autofree(c)
	var ev: EventResource = load("res://data/events/supply_raid.tres") as EventResource
	es.register_event(ev)
	var rolled: EventResource = es.roll_random("random")
	assert_not_null(rolled)
	var before_supplies: int = c.supplies
	var before_renown: int = c.renown
	var before_morale: int = c.morale
	# primeira escolha (Lutar) dá renown+5 morale+5
	es.apply_choice(rolled, 0)
	assert_eq(c.renown, before_renown + 5, "Lutar deve dar +5 renown")
	assert_eq(c.morale, before_morale + 5, "Lutar deve dar +5 morale")
	assert_eq(c.supplies, before_supplies, "Lutar não consome supplies")
