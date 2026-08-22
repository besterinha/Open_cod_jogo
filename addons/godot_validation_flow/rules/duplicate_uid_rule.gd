@tool
extends VFValidatorRule

## Same UID assigned to more than one resource path (move/copy corruption).

const RULE_ID := "duplicate_uid"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Duplicate UID"

func get_description() -> String:
	return "Detects Resource UIDs that map to multiple paths (unsafe for references)."

func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	var found: Array[VFValidationIssue] = []
	var uid_to_paths: Dictionary = {} # uid_text -> Dictionary path->true
	var paths := VFScanScope.list_files(PackedStringArray(["tscn", "scn", "tres", "res", "gd", "cs"]))
	var extra := _list_assets_with_uid()
	for p in extra:
		if not p in paths:
			paths.append(p)
	var total := maxi(paths.size(), 1)
	var i := 0
	for path in paths:
		if should_abort.call():
			break
		i += 1
		if i % 32 == 0:
			report_progress.call(100.0 * float(i) / float(total))
		if VFValidationSettings.is_path_ignored(path):
			continue
		var uid_id := ResourceLoader.get_resource_uid(path)
		if uid_id == ResourceUID.INVALID_ID:
			continue
		var uid_text := ResourceUID.id_to_text(uid_id)
		if uid_text.is_empty():
			continue
		if not uid_to_paths.has(uid_text):
			uid_to_paths[uid_text] = {}
		uid_to_paths[uid_text][path] = true

	report_progress.call(90.0)
	var keys: Array = uid_to_paths.keys()
	keys.sort()
	for uid_text in keys:
		var path_map: Dictionary = uid_to_paths[uid_text]
		if path_map.size() < 2:
			continue
		var path_list: Array = path_map.keys()
		path_list.sort()
		var primary := str(path_list[0])
		for j in range(1, path_list.size()):
			var other := str(path_list[j])
			found.append(
				VFValidationIssue.create(
					RULE_ID,
					"Duplicate UID %s shared by multiple resources" % uid_text,
					primary,
					other,
					VFValidationIssue.Severity.ERROR
				)
			)
	report_progress.call(100.0)
	return found

func _list_assets_with_uid() -> PackedStringArray:
	# Broader asset sweep still scoped by profile.
	return VFScanScope.list_files(
		PackedStringArray(["png", "svg", "jpg", "jpeg", "webp", "wav", "ogg", "mp3", "ttf", "otf", "woff", "woff2"])
	)
