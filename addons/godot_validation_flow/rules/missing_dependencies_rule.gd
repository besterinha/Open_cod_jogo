@tool
extends VFValidatorRule

## Built-in rule #1: missing ExtResource / resource dependencies (full + incremental).

const RULE_ID := "missing_dependencies"
const VFDepPath := preload("res://addons/godot_validation_flow/core/dep_path.gd")
const SCAN_EXTENSIONS := [".tscn", ".scn", ".tres", ".res"]
const SCAN_CHUNK := 24

## path -> { "mtime": int, "missing": PackedStringArray, "deps": PackedStringArray }
var _file_cache: Dictionary = {}
## SCAN file path -> mtime
var _mtime_snapshot: Dictionary = {}
## dep path -> last known exists
var _dep_exists_snap: Dictionary = {}
## dep path -> Dictionary of referrer paths
var _reverse: Dictionary = {}

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Missing Dependencies"

func get_description() -> String:
	return "Finds scenes/resources that reference missing files (proactive; reload alone does not)."

func supports_incremental() -> bool:
	return true

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	_file_cache.clear()
	_mtime_snapshot.clear()
	_dep_exists_snap.clear()
	_reverse.clear()
	var paths := _list_project_files()
	return _scan_paths(host, paths, true, report_progress, should_abort)

func run_incremental_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	if _mtime_snapshot.is_empty() and _file_cache.is_empty():
		return run_async(host, report_progress, should_abort)

	var current_mtimes := _snapshot_scan_mtimes()
	var dirty: Dictionary = {}

	for path in current_mtimes.keys():
		if not _mtime_snapshot.has(path) or int(_mtime_snapshot[path]) != int(current_mtimes[path]):
			dirty[path] = true
	for path in _mtime_snapshot.keys():
		if not current_mtimes.has(path):
			dirty[path] = true
			_remove_referrer(str(path))

	# Existence flips on any previously seen dependency (e.g. deleted .png / restored .gd).
	for dep in _dep_exists_snap.keys():
		var was: bool = bool(_dep_exists_snap[dep])
		var now := _dep_exists(str(dep))
		if was != now:
			_dep_exists_snap[dep] = now
			var referrers: Dictionary = _reverse.get(dep, {})
			for res_path in referrers.keys():
				dirty[str(res_path)] = true

	var to_rescan: PackedStringArray = []
	for path in dirty.keys():
		var p := str(path)
		if current_mtimes.has(p) and _is_scan_path(p):
			to_rescan.append(p)

	_mtime_snapshot = current_mtimes
	if to_rescan.is_empty():
		return _flatten_issues()
	return _scan_paths(host, to_rescan, false, report_progress, should_abort)

func _scan_paths(
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
			return _flatten_issues()
		i += 1
		report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			_remove_referrer(path)
			continue
		_recompute_path(path)
	if replace_snapshot:
		_mtime_snapshot = _snapshot_scan_mtimes()
	return _flatten_issues()

func _recompute_path(path: String) -> void:
	_remove_referrer_from_reverse(path)
	var mtime := FileAccess.get_modified_time(path)
	var deps: PackedStringArray = []
	var missing: PackedStringArray = []
	for dep in ResourceLoader.get_dependencies(path):
		var info := VFDepPath.parse(dep)
		var clean: String = str(info.get("primary", ""))
		if clean.is_empty():
			continue
		if (
			not clean.begins_with("res://")
			and not clean.begins_with("user://")
			and not clean.begins_with("uid://")
		):
			continue
		# Broken-UID-with-fallback is owned by broken_uid rule — still track reverse map.
		deps.append(clean)
		var ok := VFDepPath.exists(info)
		_dep_exists_snap[clean] = ok
		if not _reverse.has(clean):
			_reverse[clean] = {}
		_reverse[clean][path] = true
		if not ok:
			# Stale UID with working fallback → broken_uid rule, not "missing file".
			if VFDepPath.is_broken_uid(dep):
				continue
			var fb: String = str(info.get("fallback", ""))
			missing.append(fb if not fb.is_empty() else clean)
	_file_cache[path] = {"mtime": mtime, "missing": missing, "deps": deps}

func _remove_referrer(path: String) -> void:
	_remove_referrer_from_reverse(path)
	_file_cache.erase(path)

func _remove_referrer_from_reverse(path: String) -> void:
	if not _file_cache.has(path):
		return
	var deps: PackedStringArray = _file_cache[path].get("deps", PackedStringArray())
	for d in deps:
		if _reverse.has(d):
			_reverse[d].erase(path)
			if _reverse[d].is_empty():
				_reverse.erase(d)

func _flatten_issues() -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var keys: Array = _file_cache.keys()
	keys.sort()
	for path in keys:
		if VFValidationSettings.is_path_ignored(str(path)):
			continue
		var missing: PackedStringArray = _file_cache[path].get("missing", PackedStringArray())
		for m in missing:
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Missing dependency: %s" % m,
					str(path),
					m,
					VFValidationIssue.Severity.WARNING
				)
			)
	return found

func _dep_exists(dep: String) -> bool:
	return VFDepPath.exists(dep)

func _list_project_files() -> PackedStringArray:
	return VFScanScope.list_files(PackedStringArray(["tscn", "scn", "tres", "res"]))

func _is_scan_path(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in ["tscn", "scn", "tres", "res"] and VFScanScope.allows_path(path)

func _snapshot_scan_mtimes() -> Dictionary:
	var snap: Dictionary = {}
	for path in _list_project_files():
		snap[path] = FileAccess.get_modified_time(path)
	return snap
