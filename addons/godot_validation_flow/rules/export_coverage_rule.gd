@tool
extends VFValidatorRule

## Scenes under the active profile that are missing from restrictive export presets.

const RULE_ID := "export_coverage"
const ExportPresets := preload("res://addons/godot_validation_flow/core/export_presets.gd")

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Export Coverage"

func get_description() -> String:
	return "When export presets use scenes/resources filters, flag project scenes not listed."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	report_progress.call(10.0)
	var listed := ExportPresets.listed_export_paths()
	if listed.is_empty():
		# No restrictive presets → nothing to cover-check.
		report_progress.call(100.0)
		return found
	var listed_set: Dictionary = {}
	for p in listed:
		listed_set[str(p)] = true
	var scenes := VFScanScope.list_files(PackedStringArray(["tscn", "scn"]))
	var total := maxi(scenes.size(), 1)
	var i := 0
	for path in scenes:
		if should_abort.call():
			break
		i += 1
		if i % 8 == 0:
			report_progress.call(10.0 + 90.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		if path.begins_with("res://addons/"):
			continue
		if listed_set.has(path):
			continue
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Scene not listed in any restrictive export preset: %s" % path.get_file(),
				path,
				ExportPresets.PRESETS_PATH,
				VFValidationIssue.Severity.WARNING
			)
		)
	report_progress.call(100.0)
	return found
