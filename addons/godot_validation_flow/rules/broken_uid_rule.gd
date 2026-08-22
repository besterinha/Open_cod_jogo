@tool
extends VFValidatorRule

## UID cache stale / missing while a fallback path (or none) remains — Odin-like asset integrity.

const RULE_ID := "broken_uid"
const VFDepPath := preload("res://addons/godot_validation_flow/core/dep_path.gd")

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Broken UID"

func get_description() -> String:
	return "Finds ExtResource UIDs that no longer resolve (often after moves) while paths may still exist."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var paths := VFScanScope.list_files(PackedStringArray(["tscn", "scn", "tres", "res"]))
	var total := maxi(paths.size(), 1)
	var i := 0
	var seen: Dictionary = {}
	for path in paths:
		if should_abort.call():
			break
		i += 1
		report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		for dep in ResourceLoader.get_dependencies(path):
			if not VFDepPath.is_broken_uid(dep):
				continue
			var key := "%s|%s" % [path, dep]
			if seen.has(key):
				continue
			seen[key] = true
			var info := VFDepPath.parse(dep)
			var related := str(info.get("uid", ""))
			var fb: String = str(info.get("fallback", ""))
			var msg: String
			if not fb.is_empty():
				msg = "Broken UID (fallback still exists): %s → %s" % [related, fb]
				related = fb
			else:
				msg = "Broken or unresolved UID: %s" % VFDepPath.display_target(dep)
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					msg,
					path,
					related if not related.is_empty() else str(info.get("primary", "")),
					VFValidationIssue.Severity.WARNING
				)
			)
	return found
