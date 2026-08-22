@tool
extends VFValidatorRule

## Assets under the scan profile that no scene/resource references (coarse orphan scan).

const RULE_ID := "orphan_assets"
const DepPath := preload("res://addons/godot_validation_flow/core/dep_path.gd")

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Orphan Assets"

func get_description() -> String:
	return "Lists resources that are never referenced by scanned scenes/resources (noisy; default Info)."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var referrer_exts := PackedStringArray(["tscn", "scn", "tres", "res"])
	var candidate_exts := PackedStringArray([
		"tscn", "scn", "tres", "res", "gd", "cs",
		"png", "svg", "jpg", "jpeg", "webp",
		"wav", "ogg", "mp3", "ttf", "otf",
	])
	var referrers := VFScanScope.list_files(referrer_exts)
	var candidates := VFScanScope.list_files(candidate_exts)
	var referenced: Dictionary = {}
	var main := str(ProjectSettings.get_setting("application/run/main_scene", "")).strip_edges()
	if not main.is_empty():
		referenced[main] = true

	var total := maxi(referrers.size(), 1)
	var i := 0
	for path in referrers:
		if should_abort.call():
			return found
		i += 1
		if i % 16 == 0:
			report_progress.call(70.0 * float(i) / float(total))
		referenced[path] = true
		for dep in ResourceLoader.get_dependencies(path):
			var info: Dictionary = DepPath.parse(dep)
			var primary: String = str(info.get("primary", ""))
			var fallback: String = str(info.get("fallback", ""))
			if primary.begins_with("uid://"):
				var id := ResourceUID.text_to_id(primary)
				if id != ResourceUID.INVALID_ID and ResourceUID.has_id(id):
					var resolved := ResourceUID.get_id_path(id)
					if not resolved.is_empty():
						referenced[resolved] = true
			elif primary.begins_with("res://") or primary.begins_with("user://"):
				referenced[primary] = true
			if not fallback.is_empty():
				referenced[fallback] = true

	for al in _autoload_paths():
		referenced[al] = true

	report_progress.call(85.0)
	for path in candidates:
		if should_abort.call():
			break
		if VFValidationSettings.is_path_ignored(path):
			continue
		if _should_skip_candidate(path):
			continue
		if referenced.has(path):
			continue
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Orphan asset (no scanned referrer): %s" % path.get_file(),
				path,
				"",
				VFValidationIssue.Severity.INFO
			)
		)
	report_progress.call(100.0)
	return found

func _should_skip_candidate(path: String) -> bool:
	if path.begins_with("res://addons/"):
		return true
	if path.begins_with("res://validators/"):
		return true
	if path.begins_with("res://.godot/"):
		return true
	return false

func _autoload_paths() -> PackedStringArray:
	var out: PackedStringArray = []
	for prop in ProjectSettings.get_property_list():
		var name := str(prop.get("name", ""))
		if not name.begins_with("autoload/"):
			continue
		var raw := str(ProjectSettings.get_setting(name, "")).strip_edges()
		if raw.is_empty():
			continue
		if raw.begins_with("*"):
			raw = raw.substr(1)
		if raw.begins_with("res://"):
			out.append(raw)
	return out
