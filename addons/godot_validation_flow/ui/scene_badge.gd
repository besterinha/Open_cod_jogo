@tool
extends Button

## Scene validation badge for the 2D/3D editor menu bar.
## Shows brand icon + issue count for the currently edited scene.

signal focus_scene_requested

const POLL_SEC := 0.35
const BrandIcon := preload("res://addons/godot_validation_flow/icon_16.png")

var _index: VFIssueIndex
var _poll: Timer
var _last_scene_path: String = ""
var _wired := false

func setup(index: VFIssueIndex) -> void:
	_index = index
	flat = true
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	expand_icon = false
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	alignment = HORIZONTAL_ALIGNMENT_CENTER
	custom_minimum_size = Vector2(0, 0)
	add_theme_constant_override("h_separation", 2)
	_ensure_wired()
	refresh()

func _ensure_wired() -> void:
	if _wired:
		return
	_wired = true
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)
	if _index != null and not _index.changed.is_connected(refresh):
		_index.changed.connect(refresh)
	_poll = Timer.new()
	_poll.wait_time = POLL_SEC
	_poll.autostart = true
	_poll.timeout.connect(_on_poll)
	add_child(_poll)

func _on_poll() -> void:
	var path := _edited_scene_path()
	if path != _last_scene_path:
		_last_scene_path = path
		refresh()

func _on_pressed() -> void:
	focus_scene_requested.emit()

func refresh() -> void:
	var path := _edited_scene_path()
	_last_scene_path = path
	var base := EditorInterface.get_base_control()

	if path.is_empty():
		icon = BrandIcon
		text = "—"
		tooltip_text = "Validation Flow — no edited scene"
		modulate = Color(1, 1, 1, 0.45)
		disabled = true
		return

	disabled = false
	var counts := {"error": 0, "warning": 0, "info": 0, "total": 0}
	if _index != null:
		counts = _index.counts_for_path(path)

	var errors := int(counts.get("error", 0))
	var warnings := int(counts.get("warning", 0))
	var infos := int(counts.get("info", 0))
	var total := int(counts.get("total", 0))
	var scene_name := path.get_file()

	text = str(total)
	icon = BrandIcon

	if total <= 0:
		modulate = Color(0.75, 1.0, 0.85, 1.0)
		tooltip_text = "Validation Flow — Scene OK\n%s\nClick to open Validation (Scene filter)" % scene_name
		return

	if errors > 0:
		modulate = Color(1.0, 0.55, 0.55, 1.0)
	elif warnings > 0:
		modulate = Color(1.0, 0.85, 0.45, 1.0)
	else:
		modulate = Color(0.7, 0.85, 1.0, 1.0)

	tooltip_text = (
		"Validation Flow — %s\n%d issue(s) — E%d · W%d · I%d\nClick to open Validation (Scene filter)"
		% [scene_name, total, errors, warnings, infos]
	)

func _edited_scene_path() -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return ""
	return root.scene_file_path.strip_edges()
