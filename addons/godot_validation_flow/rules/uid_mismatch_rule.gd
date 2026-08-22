@tool
extends VFValidatorRule

## .uid sidecar text disagrees with ResourceLoader / ResourceUID cache.

const RULE_ID := "uid_mismatch"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "UID Mismatch"

func get_description() -> String:
	return "Compares *.uid sidecar files to the engine UID cache after moves/copies."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var paths := VFScanScope.list_files(
		PackedStringArray(["tscn", "scn", "tres", "res", "gd", "cs", "png", "svg", "wav", "ogg"])
	)
	var total := maxi(paths.size(), 1)
	var i := 0
	for path in paths:
		if should_abort.call():
			break
		i += 1
		if i % 24 == 0:
			report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		var uid_file := path + ".uid"
		if not FileAccess.file_exists(uid_file):
			continue
		var f := FileAccess.open(uid_file, FileAccess.READ)
		if f == null:
			continue
		var sidecar := f.get_as_text().strip_edges()
		f.close()
		if sidecar.is_empty() or not sidecar.begins_with("uid://"):
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Malformed .uid sidecar",
					path,
					uid_file,
					VFValidationIssue.Severity.WARNING
				)
			)
			continue
		var engine_id := ResourceLoader.get_resource_uid(path)
		if engine_id == ResourceUID.INVALID_ID:
			# Sidecar exists but engine has no UID — still a mismatch signal.
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"UID sidecar present but engine has no UID for resource",
					path,
					sidecar,
					VFValidationIssue.Severity.WARNING
				)
			)
			continue
		var engine_text := ResourceUID.id_to_text(engine_id)
		if engine_text != sidecar:
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"UID sidecar (%s) != engine cache (%s)" % [sidecar, engine_text],
					path,
					sidecar,
					VFValidationIssue.Severity.ERROR
				)
			)
	return found
