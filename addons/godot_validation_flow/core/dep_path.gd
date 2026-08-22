@tool
class_name VFDepPath
extends RefCounted

## Parse Godot dependency strings: `uid://…::::res://fallback` or plain `res://…`.

static func parse(raw: String) -> Dictionary:
	var text := raw.strip_edges()
	var primary := text
	var fallback := ""
	var parts := text.split("::")
	if parts.size() >= 1:
		primary = parts[0].strip_edges()
	if parts.size() >= 3:
		fallback = parts[2].strip_edges()
	var uid := ""
	if primary.begins_with("uid://"):
		uid = primary
	return {
		"raw": text,
		"primary": primary,
		"fallback": fallback,
		"uid": uid,
	}

## True if primary or fallback resolves to an existing resource.
static func exists(raw_or_parsed: Variant) -> bool:
	var info: Dictionary
	if raw_or_parsed is Dictionary:
		info = raw_or_parsed
	else:
		info = parse(str(raw_or_parsed))
	var primary: String = str(info.get("primary", ""))
	if _path_exists(primary):
		return true
	var fallback: String = str(info.get("fallback", ""))
	if not fallback.is_empty() and _path_exists(fallback):
		return true
	return false

## UID present but cache broken while fallback path still loads.
static func is_broken_uid(raw: String) -> bool:
	var info := parse(raw)
	var uid_text: String = str(info.get("uid", ""))
	if uid_text.is_empty():
		return false
	if _uid_resolves(uid_text):
		return false
	var fallback: String = str(info.get("fallback", ""))
	# Classic stale-UID: cache miss but fallback file still on disk.
	return not fallback.is_empty() and _path_exists(fallback)

static func display_target(raw: String) -> String:
	var info := parse(raw)
	var uid_text: String = str(info.get("uid", ""))
	if not uid_text.is_empty():
		var fb: String = str(info.get("fallback", ""))
		if not fb.is_empty():
			return "%s (fallback %s)" % [uid_text, fb]
		return uid_text
	return str(info.get("primary", raw))

static func _path_exists(path: String) -> bool:
	if path.is_empty():
		return false
	if ResourceLoader.exists(path):
		return true
	if path.begins_with("uid://"):
		return _uid_resolves(path)
	return false

static func _uid_resolves(uid_text: String) -> bool:
	var id := ResourceUID.text_to_id(uid_text)
	if id == ResourceUID.INVALID_ID or not ResourceUID.has_id(id):
		return false
	var resolved := ResourceUID.get_id_path(id)
	return not resolved.is_empty() and ResourceLoader.exists(resolved)
