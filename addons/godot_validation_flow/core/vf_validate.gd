@tool
class_name VFValidate
extends RefCounted

## Convenience helpers for content `_vf_validate() -> PackedStringArray`.
## Fluent: VFValidate.begin().required(x, "x").finish()
## One-shot: VFValidate.check_required(x, "x")  # "" = ok

const BatchScript := preload("res://addons/godot_validation_flow/core/vf_validate_batch.gd")

static func begin() -> RefCounted:
	return BatchScript.new()

static func check_required(value: Variant, label: String, message: String = "") -> String:
	if _is_missing(value):
		return message if not message.is_empty() else "Required '%s' is missing or empty" % label
	return ""

static func check_res_path(path: String, label: String, message: String = "") -> String:
	var p := path.strip_edges()
	if p.is_empty():
		return ""
	if (
		p.begins_with("res://")
		or p.begins_with("user://")
		or p.begins_with("uid://")
	):
		return ""
	return message if not message.is_empty() else "'%s' should be res://, user://, or uid://" % label

static func check_assets_only(path: String, label: String, message: String = "") -> String:
	var p := path.strip_edges()
	if p.is_empty():
		return ""
	if ResourceLoader.exists(p) or FileAccess.file_exists(p):
		return ""
	return message if not message.is_empty() else "'%s' must reference an existing asset" % label

static func check_file_exists(path: String, label: String, message: String = "") -> String:
	var p := path.strip_edges()
	if p.is_empty():
		return ""
	if FileAccess.file_exists(p) or ResourceLoader.exists(p):
		return ""
	return message if not message.is_empty() else "'%s' file does not exist" % label

static func check_node_path(
	host: Node,
	path: NodePath,
	label: String,
	message: String = "",
	type_name: String = ""
) -> String:
	if path.is_empty():
		return message if not message.is_empty() else "NodePath '%s' is empty" % label
	if host == null:
		return "'%s': host node is null" % label
	var node := host.get_node_or_null(path)
	if node == null:
		return message if not message.is_empty() else "NodePath '%s' does not resolve: %s" % [label, str(path)]
	var want := type_name.strip_edges()
	if not want.is_empty() and not node.is_class(want):
		return (
			message
			if not message.is_empty()
			else "'%s' must be %s (got %s)" % [label, want, node.get_class()]
		)
	return ""

static func check_min(value: float, minimum: float, label: String, message: String = "") -> String:
	if value < minimum:
		return message if not message.is_empty() else "'%s' must be >= %s (got %s)" % [label, str(minimum), str(value)]
	return ""

static func check_max(value: float, maximum: float, label: String, message: String = "") -> String:
	if value > maximum:
		return message if not message.is_empty() else "'%s' must be <= %s (got %s)" % [label, str(maximum), str(value)]
	return ""

static func check_range(value: float, minimum: float, maximum: float, label: String, message: String = "") -> String:
	if value < minimum or value > maximum:
		return (
			message
			if not message.is_empty()
			else "'%s' must be in [%s, %s] (got %s)" % [label, str(minimum), str(maximum), str(value)]
		)
	return ""

static func check_not_empty(value: Variant, label: String, message: String = "") -> String:
	if _is_empty_collection(value):
		return message if not message.is_empty() else "'%s' must not be empty" % label
	return ""

static func check_min_length(value: Variant, minimum: int, label: String, message: String = "") -> String:
	var n := _length_of(value)
	if n < 0:
		return ""
	if n < minimum:
		return message if not message.is_empty() else "'%s' length must be >= %d (got %d)" % [label, minimum, n]
	return ""

static func check_max_length(value: Variant, maximum: int, label: String, message: String = "") -> String:
	var n := _length_of(value)
	if n < 0:
		return ""
	if n > maximum:
		return message if not message.is_empty() else "'%s' length must be <= %d (got %d)" % [label, maximum, n]
	return ""

static func check_regex(text: String, pattern: String, label: String, message: String = "") -> String:
	if text.is_empty() or pattern.is_empty():
		return ""
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return "Invalid regex for '%s'" % label
	if re.search(text) == null:
		return message if not message.is_empty() else "'%s' does not match /%s/" % [label, pattern]
	return ""

static func check_one_of(value: Variant, allowed: Array, label: String, message: String = "") -> String:
	if value in allowed:
		return ""
	return message if not message.is_empty() else "'%s' must be one of %s (got %s)" % [label, str(allowed), str(value)]

static func push(issues: PackedStringArray, message: String) -> void:
	var m := message.strip_edges()
	if not m.is_empty():
		issues.append(m)

static func _is_missing(value: Variant) -> bool:
	if value == null:
		return true
	match typeof(value):
		TYPE_STRING, TYPE_STRING_NAME:
			return str(value).strip_edges().is_empty()
		TYPE_NODE_PATH:
			return (value as NodePath).is_empty()
		TYPE_OBJECT:
			return not is_instance_valid(value)
		_:
			return false

static func _is_empty_collection(value: Variant) -> bool:
	if value == null:
		return true
	match typeof(value):
		TYPE_STRING:
			return str(value).is_empty()
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			return value.is_empty()
		TYPE_DICTIONARY:
			return (value as Dictionary).is_empty()
		_:
			return false

static func _length_of(value: Variant) -> int:
	if value == null:
		return 0
	match typeof(value):
		TYPE_STRING:
			return str(value).length()
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY:
			return value.size()
		TYPE_DICTIONARY:
			return (value as Dictionary).size()
		_:
			return -1
