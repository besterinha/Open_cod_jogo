@tool
extends VFValidatorRule

## ProjectSettings autoload entries whose script/scene path is missing.

const RULE_ID := "autoload_paths"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Autoload Paths"

func get_description() -> String:
	return "Checks that every Project Settings autoload path still exists."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	report_progress.call(20.0)
	var entries: Array[Dictionary] = []
	for prop in ProjectSettings.get_property_list():
		var name := str(prop.get("name", ""))
		if not name.begins_with("autoload/"):
			continue
		var key := name.trim_prefix("autoload/")
		var raw := str(ProjectSettings.get_setting(name, "")).strip_edges()
		if raw.is_empty():
			continue
		var singleton := raw.begins_with("*")
		if singleton:
			raw = raw.substr(1)
		entries.append({"name": key, "path": raw, "singleton": singleton})
	var total := maxi(entries.size(), 1)
	var i := 0
	for entry in entries:
		if should_abort.call():
			break
		i += 1
		report_progress.call(20.0 + 80.0 * float(i) / float(total))
		var path: String = str(entry.path)
		if path.is_empty():
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Autoload '%s' has an empty path" % entry.name,
					"res://project.godot",
					"",
					VFValidationIssue.Severity.ERROR
				)
			)
			continue
		if VFValidationSettings.is_path_ignored(path):
			continue
		if ResourceLoader.exists(path) or FileAccess.file_exists(path):
			continue
		found.append(
			VFValidationIssue.create(
				RULE_ID,
				"Autoload '%s' path missing: %s" % [entry.name, path],
				"res://project.godot",
				path,
				VFValidationIssue.Severity.ERROR
			)
		)
	return found
