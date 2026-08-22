@tool
extends VFValidatorRule

## Exported NodePath properties that are empty (common scene wiring miss).

const RULE_ID := "empty_node_paths"
const DepPath := preload("res://addons/godot_validation_flow/core/dep_path.gd")

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Empty NodePaths"

func get_description() -> String:
	return "Flags empty exported NodePath properties on nodes inside packed scenes."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var scenes := VFScanScope.list_files(PackedStringArray(["tscn", "scn"]))
	var total := maxi(scenes.size(), 1)
	var i := 0
	for path in scenes:
		if should_abort.call():
			break
		i += 1
		report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		if _has_missing_deps(path):
			continue
		if not ResourceLoader.exists(path):
			continue
		var packed: PackedScene = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE) as PackedScene
		if packed == null:
			continue
		var root: Node = packed.instantiate()
		if root == null:
			continue
		_walk(root, path, str(root.name), found)
		root.queue_free()
	return found

func _has_missing_deps(path: String) -> bool:
	for dep in ResourceLoader.get_dependencies(path):
		if not DepPath.exists(dep):
			return true
	return false

func _walk(node: Node, scene_path: String, node_path: String, found: Array[VFValidationIssue]) -> void:
	for prop in node.get_property_list():
		var usage: int = int(prop.get("usage", 0))
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0:
			continue
		if (usage & PROPERTY_USAGE_EDITOR) == 0:
			continue
		if int(prop.get("type", 0)) != TYPE_NODE_PATH:
			continue
		var pname := str(prop.get("name", ""))
		if pname.is_empty() or pname.begins_with("_"):
			continue
		var value: Variant = node.get(pname)
		if typeof(value) != TYPE_NODE_PATH:
			continue
		if not (value as NodePath).is_empty():
			continue
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Empty NodePath export '%s' on %s" % [pname, node_path],
				scene_path,
				node_path,
				VFValidationIssue.Severity.INFO
			)
		)
	for child in node.get_children():
		_walk(child, scene_path, node_path.path_join(str(child.name)), found)
