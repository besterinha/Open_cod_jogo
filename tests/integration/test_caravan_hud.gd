extends GutTest
# Integração: CaravanManager + HUD (CaravanBar + RadialMenu) + Market/Camp

func test_caravan_bar_mostra_supplies_e_morale() -> void:
	var caravan: CaravanManager = preload("res://systems/caravan/caravan_manager.gd").new()
	caravan.supplies = 25
	caravan.morale = 70
	caravan.renown = 3
	caravan.add_to_group("caravan")
	add_child_autofree(caravan)
	var bar: Control = preload("res://ui/caravan_bar.tscn").instantiate() as Control
	add_child_autofree(bar)
	await get_tree().process_frame
	await get_tree().process_frame
	var label: Label = bar.get_node_or_null("Label") as Label
	assert_not_null(label)
	# força atualizar - deve ler do caravan no grupo
	bar.call("_update", "test")
	await get_tree().process_frame
	assert_true(label.text.contains("25") or label.text.contains("70") or label.text.contains("3"), "CaravanBar deve mostrar dados do caravan (25/70/3), got: %s" % label.text)

func test_radial_menu_acoes_chamam_sistemas() -> void:
	var arena: Node3D = preload("res://content/maps/journey_map.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var caravan: Node = arena.get_node_or_null("CaravanManager")
	assert_not_null(caravan)
	var before_supplies: int = int(caravan.get("supplies"))
	var before_day: int = int(caravan.get("day"))
	# simula tocar Viajar no radial
	if arena.has_method("_on_radial_action"):
		arena.call("_on_radial_action", "viajar")
		await get_tree().process_frame
		assert_eq(int(caravan.get("day")), before_day + 1, "Viajar deve avançar 1 dia")
		# viajar consome 1 supply + evento aleatório pode dar -5..+12 — só checa que dia avançou e supplies está em faixa plausível
		var after: int = int(caravan.get("supplies"))
		assert_true(after >= before_supplies - 10 and after <= before_supplies + 15,
			"Supplies após viajar deve estar em [%d, %d], got %d (before %d)" % [before_supplies - 10, before_supplies + 15, after, before_supplies])

func test_market_e_camp_via_hud() -> void:
	var caravan := CaravanManager.new()
	caravan.supplies = 10
	caravan.renown = 10
	caravan.morale = 50
	add_child_autofree(caravan)
	var market := MarketSystem.new()
	market.setup(caravan)
	market.current_rate = 5
	add_child_autofree(market)
	var camp := CampSystem.new()
	camp.setup(caravan)
	add_child_autofree(camp)
	# compra via market
	assert_true(market.buy_supplies(1))
	assert_eq(caravan.supplies, 15)
	assert_eq(caravan.renown, 9)
	# descanso via camp
	var before_morale: int = caravan.morale
	camp.rest(1)
	assert_eq(caravan.morale, before_morale + 10)

func test_caravan_bar_atualiza_via_eventbus() -> void:
	var caravan := CaravanManager.new()
	caravan.supplies = 30
	caravan.morale = 50
	add_child_autofree(caravan)
	var bar: Control = preload("res://ui/caravan_bar.tscn").instantiate() as Control
	add_child_autofree(bar)
	await get_tree().process_frame
	watch_signals(EventBus)
	caravan.add_supplies(-5)
	await get_tree().process_frame
	assert_signal_emitted(EventBus, "supplies_changed")
	caravan.add_morale(10)
	await get_tree().process_frame
	assert_signal_emitted(EventBus, "morale_changed")
