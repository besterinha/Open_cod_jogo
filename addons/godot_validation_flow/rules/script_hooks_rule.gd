@tool
extends VFValidatorRule

## Built-in: collect `_vf_validate` / C# hooks / optional [VfRequired] (via VfCsharpBridge).
## Project config toggles the rule; authors put checks on content scripts (GD or C#).

const RULE_ID := "script_hooks"
const SCAN_CHUNK := 12

var _mtime_snapshot: Dictionary = {}
var _issues_by_scene: Dictionary = {}

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Script Hooks"

func get_description() -> String:
	return "Calls _vf_validate() on nodes in packed scenes (content inject)."

func supports_incremental() -> bool:
	return true

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	_mtime_snapshot.clear()
	_issues_by_scene.clear()
	return _scan_scenes(host, _list_scenes(), true, report_progress, should_abort)

func run_incremental_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	if _mtime_snapshot.is_empty() and _issues_by_scene.is_empty():
		return run_async(host, report_progress, should_abort)
	var current := _snapshot_mtimes()
	var dirty: PackedStringArray = []
	for path in current.keys():
		if not _mtime_snapshot.has(path) or int(_mtime_snapshot[path]) != int(current[path]):
			dirty.append(str(path))
	for path in _mtime_snapshot.keys():
		if not current.has(path):
			_issues_by_scene.erase(path)
	_mtime_snapshot = current
	if dirty.is_empty():
		return _flatten()
	return _scan_scenes(host, dirty, false, report_progress, should_abort)

func _scan_scenes(
	host: Node,
	paths: PackedStringArray,
	replace_snapshot: bool,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var total := maxi(paths.size(), 1)
	var i := 0
	for path in paths:
		if should_abort.call():
			return _flatten()
		i += 1
		report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			_issues_by_scene.erase(path)
			continue
		_issues_by_scene[path] = _collect_for_scene(path)
	if replace_snapshot:
		_mtime_snapshot = _snapshot_mtimes()
	return _flatten()

func _collect_for_scene(path: String) -> Array[VFValidationIssue]:
	var out: Array[VFValidationIssue] = []
	if not ResourceLoader.exists(path):
		return out
	for dep in ResourceLoader.get_dependencies(path):
		var clean := dep
		var sep := clean.find("::")
		if sep != -1:
			clean = clean.substr(0, sep)
		clean = clean.strip_edges()
		if clean.is_empty():
			continue
		if clean.begins_with("res://") or clean.begins_with("uid://"):
			if not ResourceLoader.exists(clean):
				if clean.begins_with("uid://"):
					var id := ResourceUID.text_to_id(clean)
					if id == ResourceUID.INVALID_ID or not ResourceUID.has_id(id):
						return out
					var resolved := ResourceUID.get_id_path(id)
					if resolved.is_empty() or not ResourceLoader.exists(resolved):
						return out
				else:
					return out
	var packed := load(path) as PackedScene
	if packed == null:
		return out
	var root: Node = packed.instantiate()
	if root == null:
		return out
	var severity := VFValidationSettings.get_script_hooks_severity()
	_walk_hooks(root, path, str(root.name), severity, out)
	root.queue_free()
	return out

func _walk_hooks(
	node: Node,
	scene_path: String,
	node_path: String,
	severity: int,
	out: Array[VFValidationIssue]
) -> void:
	for msg in _read_hook(node):
		var text := str(msg).strip_edges()
		if text.is_empty():
			continue
		out.append(
			VFValidationIssue.create(RULE_ID, text, scene_path, node_path, severity)
		)
	for child in node.get_children():
		_walk_hooks(child, scene_path, node_path.path_join(str(child.name)), severity, out)

## GDScript `_vf_validate` + C# bridge (hooks + optional [VfRequired]).
func _read_hook(node: Node) -> PackedStringArray:
	var bridge := _try_csharp_bridge()
	if bridge != null:
		var from_cs: Variant = bridge.call(
			"CollectNodeIssues",
			node,
			true,
			VFValidationSettings.is_csharp_attributes_enabled()
		)
		return _normalize_hook_result(from_cs)
	return _call_hook_methods(node)

func _call_hook_methods(node: Node) -> PackedStringArray:
	const NAMES := ["_vf_validate", "_VfValidate", "VfValidate", "vf_validate"]
	for method_name in NAMES:
		if not node.has_method(method_name):
			continue
		return _normalize_hook_result(node.call(method_name))
	return PackedStringArray()

func _try_csharp_bridge() -> RefCounted:
	if ClassDB.class_exists("VfCsharpBridge"):
		var via_class: Variant = ClassDB.instantiate("VfCsharpBridge")
		if via_class is RefCounted:
			return via_class as RefCounted
	# Headless / before global-class cache: instantiate from C# script resource.
	var script: Variant = load("res://addons/godot_validation_flow/csharp/VfCsharpBridge.cs")
	if script != null and script.has_method("new"):
		var via_script: Variant = script.new()
		if via_script is RefCounted:
			return via_script as RefCounted
	return null

func _normalize_hook_result(result: Variant) -> PackedStringArray:
	if result is PackedStringArray:
		return result
	if result is Array:
		var packed := PackedStringArray()
		for item in result:
			packed.append(str(item))
		return packed
	if typeof(result) == TYPE_STRING and not str(result).is_empty():
		return PackedStringArray([str(result)])
	return PackedStringArray()

func _flatten() -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var keys: Array = _issues_by_scene.keys()
	keys.sort()
	for path in keys:
		if VFValidationSettings.is_path_ignored(str(path)):
			continue
		for issue in _issues_by_scene[path]:
			found.append(issue)
	return found

func _list_scenes() -> PackedStringArray:
	return VFScanScope.list_files(PackedStringArray(["tscn", "scn"]))

func _snapshot_mtimes() -> Dictionary:
	var snap: Dictionary = {}
	for path in _list_scenes():
		snap[path] = FileAccess.get_modified_time(path)
	return snap
