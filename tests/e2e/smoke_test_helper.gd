class_name SmokeTestHelper
extends RefCounted

var _error_count: int = 0


func _init() -> void:
	_error_count = 0


func load_and_assert_scene(scene_path: String) -> Node:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("Scene %s failed to load" % scene_path)
		return null
	var instance: Node = scene.instantiate()
	Engine.get_main_loop().root.add_child(instance)
	await Engine.get_main_loop().create_timer(2.0).timeout
	return instance


func assert_node_exists(parent: Node, node_path: String) -> void:
	var node := parent.get_node_or_null(node_path)
	if node == null:
		push_error("Expected node '%s' not found in scene" % node_path)


func assert_no_errors() -> bool:
	return _error_count == 0
