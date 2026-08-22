@tool
class_name VFValidationProfile
extends Resource

## Odin-like validation profile: **what to scan** (data only).
## Create New Resource → search "VFValidationProfile".

@export var display_name: String = "Full Project"
## Paths that may be scanned (prefix match). Empty → treat as res://
@export var include_prefixes: PackedStringArray = PackedStringArray(["res://"])
## Paths to skip (prefix match), applied after includes.
@export var exclude_prefixes: PackedStringArray = PackedStringArray()
@export var skip_addons: bool = true

static func make_default() -> VFValidationProfile:
	var p := VFValidationProfile.new()
	p.display_name = "Full Project"
	p.include_prefixes = PackedStringArray(["res://"])
	p.skip_addons = true
	return p

func allows_path(path: String) -> bool:
	if path.is_empty():
		return false
	if VFValidationSettings.is_path_ignored(path):
		return false
	if skip_addons and (path.begins_with("res://addons/") or path.contains("/addons/")):
		return false
	var includes := include_prefixes
	if includes.is_empty():
		includes = PackedStringArray(["res://"])
	var ok := false
	for prefix in includes:
		var p := str(prefix).strip_edges()
		if p.is_empty():
			continue
		if path == p or path.begins_with(p):
			ok = true
			break
	if not ok:
		return false
	for prefix in exclude_prefixes:
		var p2 := str(prefix).strip_edges()
		if p2.is_empty():
			continue
		if path == p2 or path.begins_with(p2):
			return false
	return true

func get_scan_roots() -> PackedStringArray:
	var roots: PackedStringArray = []
	var includes := include_prefixes
	if includes.is_empty():
		includes = PackedStringArray(["res://"])
	for prefix in includes:
		var p := str(prefix).strip_edges()
		if p.is_empty():
			continue
		if not p.ends_with("/") and p != "res://":
			# File include: parent dir walk still needed; allow as root file filter via allows_path
			var base := p.get_base_dir()
			if base.is_empty():
				base = "res://"
			if base not in roots:
				roots.append(base)
		else:
			if p not in roots:
				roots.append(p)
	if roots.is_empty():
		roots.append("res://")
	return roots
