extends GutTest

func test_journey_map_loads() -> void:
	var res: Resource = load("res://content/maps/journey_map.tscn")
	assert_not_null(res, "journey_map.tscn não carrega")
	if res is PackedScene:
		var inst: Node = (res as PackedScene).instantiate()
		assert_not_null(inst)
		add_child_autofree(inst)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_true(inst.has_node("CaravanManager"))
		assert_true(inst.has_node("TravelSystem"))
		assert_true(inst.has_node("CampSystem"))
		assert_true(inst.has_node("MarketSystem"))
		assert_true(inst.has_node("EventSystem"))
		assert_true(inst.has_node("CanvasLayer/CaravanBar"), "CaravanBar deve existir")
		assert_true(inst.has_node("CanvasLayer/RadialMenu"), "RadialMenu deve existir")

func test_tactical_arena_still_loads() -> void:
	var res: Resource = load("res://content/maps/tactical_arena.tscn")
	assert_not_null(res)
