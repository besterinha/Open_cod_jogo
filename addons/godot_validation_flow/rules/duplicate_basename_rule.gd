@tool
extends VFValidatorRule

## Same basename in multiple folders (easy to open the wrong scene/script).

const RULE_ID := "duplicate_basename"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Duplicate Basename"

func get_description() -> String:
	return "Flags identical file names under different folders within the scan profile."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var paths := VFScanScope.list_files(PackedStringArray(["tscn", "scn", "tres", "res", "gd", "cs"]))
	var by_name: Dictionary = {} # basename -> Array[String]
	var total := maxi(paths.size(), 1)
	var i := 0
	for path in paths:
		if should_abort.call():
			break
		i += 1
		if i % 32 == 0:
			report_progress.call(80.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		if path.begins_with("res://addons/"):
			continue
		var base := path.get_file()
		if not by_name.has(base):
			by_name[base] = []
		by_name[base].append(path)

	report_progress.call(90.0)
	var keys: Array = by_name.keys()
	keys.sort()
	for base in keys:
		var list: Array = by_name[base]
		if list.size() < 2:
			continue
		list.sort()
		var primary := str(list[0])
		for j in range(1, list.size()):
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Duplicate basename '%s'" % base,
					primary,
					str(list[j]),
					VFValidationIssue.Severity.INFO
				)
			)
	report_progress.call(100.0)
	return found
