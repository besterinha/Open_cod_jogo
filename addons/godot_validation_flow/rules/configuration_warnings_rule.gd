@tool
extends VFValidatorRule

## Built-in rule #2: aggregate Node.get_configuration_warnings() from packed scenes.

const RULE_ID := "configuration_warnings"
const SCAN_CHUNK := 12

var _mtime_snapshot: Dictionary = {}
var _issues_by_scene: Dictionary = {} # scene path -> Array[VFValidationIssue]

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Configuration Warnings"

func get_description() -> String:
	return "Instantiates .tscn/.scn scenes and collects get_configuration_warnings() from all nodes."

func supports_incremental() -> bool:
	return true

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	_mtime_snapshot.clear()
	_issues_by_scene.clear()
	var paths := _list_scenes()
	return _scan_scenes(host, paths, true, report_progress, should_abort)

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
	# Skip scenes that already fail dependency load — Missing Dependencies covers them.
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
	_walk_warnings(root, path, str(root.name), out)
	root.queue_free()
	return out

func _walk_warnings(node: Node, scene_path: String, node_path: String, out: Array[VFValidationIssue]) -> void:
	var warnings := _read_warnings(node)
	for w in warnings:
		if str(w).strip_edges().is_empty():
			continue
		out.append(
			VFValidationIssue.create(
				RULE_ID,
				str(w),
				scene_path,
				node_path,
				VFValidationIssue.Severity.WARNING
			)
		)
	for child in node.get_children():
		var child_path := node_path.path_join(str(child.name))
		_walk_warnings(child, scene_path, child_path, out)

func _read_warnings(node: Node) -> PackedStringArray:
	# Editor exposes get_configuration_warnings(); headless/CLI may only have the virtual.
	if node.has_method("get_configuration_warnings"):
		var w: Variant = node.call("get_configuration_warnings")
		if w is PackedStringArray:
			return w
	if node.has_method("_get_configuration_warnings"):
		var w2: Variant = node.call("_get_configuration_warnings")
		if w2 is PackedStringArray:
			return w2
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
