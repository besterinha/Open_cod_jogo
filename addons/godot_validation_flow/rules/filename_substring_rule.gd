@tool
extends VFValidatorRule

## Built-in: flag files whose basename contains a configured substring.
## Configured entirely via ProjectSettings — no project scripts required.

const RULE_ID := "filename_substring"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Filename Substring"

func get_description() -> String:
	return "Flags resources whose file name contains a forbidden substring (Project Settings)."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var needle := VFValidationSettings.get_filename_substring()
	if needle.is_empty():
		return found
	var exts := VFValidationSettings.get_filename_extensions()
	var severity := VFValidationSettings.get_filename_severity()
	var paths := _list_matching_files(exts)
	var total := maxi(paths.size(), 1)
	var i := 0
	for path in paths:
		if should_abort.call():
			break
		i += 1
		report_progress.call(100.0 * float(i) / float(total))
		if path.get_file().find(needle) != -1:
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Filename contains '%s'" % needle,
					path,
					"",
					severity
				)
			)
	return found

func _list_matching_files(exts: PackedStringArray) -> PackedStringArray:
	return VFScanScope.list_files(exts)
