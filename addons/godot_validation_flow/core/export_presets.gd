@tool
class_name VFExportPresets
extends RefCounted

## Shared reader for res://export_presets.cfg (EditorExport preset APIs are not bound to GDScript).

const PRESETS_PATH := "res://export_presets.cfg"

static func load_all() -> Array[Dictionary]:
	if not FileAccess.file_exists(PRESETS_PATH):
		return []
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

## Union of explicit scene/resource paths from presets that are NOT all_resources.
## Empty return means "no restrictive presets" (skip coverage checks).
static func listed_export_paths() -> PackedStringArray:
	var presets := load_all()
	var listed: Dictionary = {}
	var any_restrictive := false
	for preset in presets:
		var filter: String = str(preset.get("export_filter", "all_resources"))
		if filter == "all_resources":
			continue
		any_restrictive = true
		if filter in ["scenes", "resources", "exclude"]:
			for f in preset.get("export_files", PackedStringArray()):
				listed[str(f)] = true
		elif filter == "customized":
			var customized: Dictionary = preset.get("customized_files", {})
			for path in customized.keys():
				listed[str(path)] = true
	if not any_restrictive:
		return PackedStringArray()
	var out: PackedStringArray = PackedStringArray()
	for path in listed.keys():
		out.append(str(path))
	out.sort()
	return out
