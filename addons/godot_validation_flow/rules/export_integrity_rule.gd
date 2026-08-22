@tool
extends VFValidatorRule

## Main scene + export_presets.cfg integrity (Godot has no GDScript EditorExport preset API).

const RULE_ID := "export_integrity"
const PRESETS_PATH := "res://export_presets.cfg"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Export Integrity"

func get_description() -> String:
	return "Checks main scene and export preset file lists so shipping builds do not silently drop assets."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	report_progress.call(10.0)
	_check_main_scene(found)
	if should_abort.call():
		return found
	report_progress.call(40.0)
	_check_export_presets(found, should_abort)
	report_progress.call(100.0)
	return found

func _check_main_scene(found: Array[VFValidationIssue]) -> void:
	var main := str(ProjectSettings.get_setting("application/run/main_scene", "")).strip_edges()
	if main.is_empty():
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Project has no main scene (application/run/main_scene)",
				"res://project.godot",
				"",
				VFValidationIssue.Severity.WARNING
			)
		)
		return
	if not ResourceLoader.exists(main):
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Main scene missing: %s" % main,
				"res://project.godot",
				main,
				VFValidationIssue.Severity.ERROR
			)
		)

func _check_export_presets(found: Array[VFValidationIssue], should_abort: Callable) -> void:
	if not FileAccess.file_exists(PRESETS_PATH):
		# Early projects often have none — keep noise low.
		return
	var presets := _load_export_presets()
	if presets.is_empty():
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"export_presets.cfg present but no presets parsed",
				PRESETS_PATH,
				"",
				VFValidationIssue.Severity.INFO
			)
		)
		return
	var main := str(ProjectSettings.get_setting("application/run/main_scene", "")).strip_edges()
	for preset in presets:
		if should_abort.call():
			return
		var pname: String = str(preset.get("name", "preset"))
		var filter: String = str(preset.get("export_filter", "all_resources"))
		var files: PackedStringArray = preset.get("export_files", PackedStringArray())
		match filter:
			"scenes", "resources", "exclude":
				for f in files:
					var path := str(f).strip_edges()
					if path.is_empty():
						continue
					if VFValidationSettings.is_path_ignored(path):
						continue
					if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
						found.append(
							VFValidationIssue.create(
								RULE_ID,
								"Export preset '%s' lists missing file: %s" % [pname, path],
								PRESETS_PATH,
								path,
								VFValidationIssue.Severity.ERROR
							)
						)
				if (
					filter == "scenes"
					and not main.is_empty()
					and ResourceLoader.exists(main)
					and files.size() > 0
					and not _packed_has(files, main)
				):
					found.append(
						VFValidationIssue.create(
							RULE_ID,
							"Export preset '%s' (scenes) does not include main scene %s" % [pname, main],
							PRESETS_PATH,
							main,
							VFValidationIssue.Severity.WARNING
						)
					)
			"customized":
				var customized: Dictionary = preset.get("customized_files", {})
				for path in customized.keys():
					var p := str(path).strip_edges()
					if p.is_empty() or VFValidationSettings.is_path_ignored(p):
						continue
					# Values are typically include/exclude markers; missing path is always wrong.
					if not ResourceLoader.exists(p) and not FileAccess.file_exists(p):
						found.append(
							VFValidationIssue.create(
								RULE_ID,
								"Export preset '%s' customized entry missing: %s" % [pname, p],
								PRESETS_PATH,
								p,
								VFValidationIssue.Severity.ERROR
							)
						)
			_:
				pass

func _load_export_presets() -> Array[Dictionary]:
	var cfg := ConfigFile.new()
	if cfg.load(PRESETS_PATH) != OK:
		return []
	var out: Array[Dictionary] = []
	var i := 0
	while cfg.has_section("preset.%d" % i):
		var section := "preset.%d" % i
		var filter := str(cfg.get_value(section, "export_filter", "all_resources"))
		var files: PackedStringArray = PackedStringArray()
		if filter in ["scenes", "resources", "exclude"]:
			var v: Variant = cfg.get_value(section, "export_files", PackedStringArray())
			if v is PackedStringArray:
				files = v
			elif v is Array:
				for x in v:
					files.append(str(x))
		var customized: Dictionary = {}
		if filter == "customized":
			var c: Variant = cfg.get_value(section, "customized_files", {})
			if c is Dictionary:
				customized = c
		out.append({
			"index": i,
			"name": str(cfg.get_value(section, "name", "")),
			"platform": str(cfg.get_value(section, "platform", "")),
			"export_filter": filter,
			"export_files": files,
			"customized_files": customized,
		})
		i += 1
	return out

func _packed_has(files: PackedStringArray, path: String) -> bool:
	for f in files:
		if str(f) == path:
			return true
	return false
