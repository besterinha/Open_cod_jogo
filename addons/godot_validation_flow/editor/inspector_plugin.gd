@tool
extends EditorInspectorPlugin

## Shows Validation issues for the inspected Node / Resource.

const BannerScript := preload("res://addons/godot_validation_flow/ui/inspector_banner.gd")

var _index: VFIssueIndex
var _on_open: Callable
var _on_focus: Callable

func setup(index: VFIssueIndex, on_open: Callable, on_focus: Callable) -> void:
	_index = index
	_on_open = on_open
	_on_focus = on_focus

func _can_handle(object: Object) -> bool:
	if object == null or _index == null:
		return false
	return not _index.for_object(object).is_empty()

func _parse_begin(object: Object) -> void:
	if _index == null:
		return
	var issues := _index.for_object(object)
	if issues.is_empty():
		return
	var banner: Control = BannerScript.new()
	banner.populate(issues, _on_open, _on_focus)
	add_custom_control(banner)
