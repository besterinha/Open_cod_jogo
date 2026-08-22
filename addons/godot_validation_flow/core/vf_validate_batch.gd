@tool
class_name VFValidateBatch
extends RefCounted

## Fluent batch from VFValidate.begin().

const Checks := preload("res://addons/godot_validation_flow/core/vf_validate.gd")

var _issues: PackedStringArray = []

func required(value: Variant, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_required(value, label, message))
	return self

func res_path(path: String, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_res_path(path, label, message))
	return self

func assets_only(path: String, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_assets_only(path, label, message))
	return self

func file_exists(path: String, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_file_exists(path, label, message))
	return self

func node_path(
	host: Node,
	path: NodePath,
	label: String,
	message: String = "",
	type_name: String = ""
) -> VFValidateBatch:
	Checks.push(_issues, Checks.check_node_path(host, path, label, message, type_name))
	return self

func min_value(value: float, minimum: float, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_min(value, minimum, label, message))
	return self

func max_value(value: float, maximum: float, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_max(value, maximum, label, message))
	return self

func range_value(value: float, minimum: float, maximum: float, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_range(value, minimum, maximum, label, message))
	return self

func not_empty(value: Variant, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_not_empty(value, label, message))
	return self

func min_length(value: Variant, minimum: int, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_min_length(value, minimum, label, message))
	return self

func max_length(value: Variant, maximum: int, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_max_length(value, maximum, label, message))
	return self

func regex(text: String, pattern: String, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_regex(text, pattern, label, message))
	return self

func one_of(value: Variant, allowed: Array, label: String, message: String = "") -> VFValidateBatch:
	Checks.push(_issues, Checks.check_one_of(value, allowed, label, message))
	return self

func custom(message: String) -> VFValidateBatch:
	Checks.push(_issues, message)
	return self

func finish() -> PackedStringArray:
	return _issues
