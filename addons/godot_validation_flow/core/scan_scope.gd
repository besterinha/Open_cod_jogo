@tool
class_name VFScanScope
extends RefCounted

## Shared filesystem walk honoring the active VFValidationProfile.

static func get_profile() -> VFValidationProfile:
	return VFValidationSettings.get_active_profile()

static func allows_path(path: String) -> bool:
	return get_profile().allows_path(path)

## extensions: "tscn" or ".tscn" (case-insensitive). Empty = all files that pass profile.
static func list_files(extensions: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	var allowed: Dictionary = {}
	for e in extensions:
		var key := str(e).strip_edges().trim_prefix(".").to_lower()
		if not key.is_empty():
			allowed[key] = true
	var out: PackedStringArray = []
	var profile := get_profile()
	for root in profile.get_scan_roots():
		_walk(root, out, allowed)
	return out

static func _walk(dir_path: String, out: PackedStringArray, allowed: Dictionary) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	if dir.file_exists(".gdignore"):
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full := dir_path.path_join(name)
		if dir.current_is_dir():
			if name == ".godot":
				name = dir.get_next()
				continue
			# Still descend; allows_path filters files (and skip_addons blocks addons paths).
			if VFScanScope.allows_path(full + "/") or VFScanScope.allows_path(full) or _dir_may_contain_includes(full):
				_walk(full, out, allowed)
		else:
			if not allowed.is_empty() and not allowed.has(name.get_extension().to_lower()):
				name = dir.get_next()
				continue
			if VFScanScope.allows_path(full):
				out.append(full)
		name = dir.get_next()
	dir.list_dir_end()

## Descend if any include prefix lives under this directory.
static func _dir_may_contain_includes(dir_path: String) -> bool:
	var profile := get_profile()
	if not profile.skip_addons and dir_path.begins_with("res://addons"):
		return true
	if profile.skip_addons and (dir_path == "res://addons" or dir_path.begins_with("res://addons/")):
		return false
	for prefix in profile.include_prefixes:
		var p := str(prefix).strip_edges()
		if p.is_empty():
			continue
		if p.begins_with(dir_path) or dir_path.begins_with(p):
			return true
	# Default full-project include res://
	if profile.include_prefixes.is_empty() or "res://" in profile.include_prefixes:
		return not (profile.skip_addons and dir_path.begins_with("res://addons"))
	return false
