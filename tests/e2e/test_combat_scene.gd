extends GdUnitTestSuite

const SCENE_PATH: String = "res://src/scenes/combat_scene.tscn"


func test_combat_scene_loads() -> void:
	var helper := SmokeTestHelper.new()
	var scene: Node = await helper.load_and_assert_scene(SCENE_PATH)
	if scene == null:
		return
	helper.assert_node_exists(scene, "GridSystem")
	helper.assert_node_exists(scene, "Hero")
	helper.assert_node_exists(scene, "Camera")
	helper.assert_node_exists(scene, "TouchController")
	scene.queue_free()
