@tool
extends PanelContainer

## Compact Validation summary shown at the top of the Inspector.

signal open_requested(issue: VFValidationIssue)
signal focus_panel_requested

const MAX_ROWS := 5

var _title: Label
var _list: VBoxContainer
var _open_btn: Button

func _ready() -> void:
	_build_if_needed()

func populate(issues: Array[VFValidationIssue], on_open: Callable, on_focus: Callable) -> void:
	_build_if_needed()
	if open_requested.get_connections().is_empty() and on_open.is_valid():
		open_requested.connect(func(issue: VFValidationIssue) -> void: on_open.call(issue))
	if focus_panel_requested.get_connections().is_empty() and on_focus.is_valid():
		focus_panel_requested.connect(func() -> void: on_focus.call())

	for child in _list.get_children():
		child.queue_free()

	var errors := 0
	var warnings := 0
	var infos := 0
	for issue in issues:
		match int(issue.severity):
			VFValidationIssue.Severity.ERROR:
				errors += 1
			VFValidationIssue.Severity.INFO:
				infos += 1
			_:
				warnings += 1

	var parts: PackedStringArray = []
	if errors > 0:
		parts.append("E%d" % errors)
	if warnings > 0:
		parts.append("W%d" % warnings)
	if infos > 0:
		parts.append("I%d" % infos)
	_title.text = "Validation · %s" % (" · ".join(parts) if not parts.is_empty() else "%d" % issues.size())

	var base := EditorInterface.get_base_control()
	var shown := 0
	for issue in issues:
		if shown >= MAX_ROWS:
			break
		var row := Button.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.flat = true
		row.clip_text = true
		row.text = "[%s] %s" % [VFReportWriter.severity_name(issue.severity), issue.message]
		row.tooltip_text = "%s\n%s\n%s" % [issue.rule_id, issue.resource_path, issue.related_path]
		row.icon = base.get_theme_icon("StatusWarning", "EditorIcons")
		var captured := issue
		row.pressed.connect(func() -> void: open_requested.emit(captured))
		_list.add_child(row)
		shown += 1

	if issues.size() > MAX_ROWS:
		var more := Label.new()
		more.text = "+%d more — open Validation panel" % (issues.size() - MAX_ROWS)
		more.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_list.add_child(more)

func _build_if_needed() -> void:
	if _title != null:
		return
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 6)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title = Label.new()
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.clip_text = true
	header.add_child(_title)

	_open_btn = Button.new()
	_open_btn.text = "Panel"
	_open_btn.flat = true
	_open_btn.tooltip_text = "Focus Validation bottom panel"
	_open_btn.pressed.connect(func() -> void: focus_panel_requested.emit())
	header.add_child(_open_btn)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	vbox.add_child(_list)

	# Subtle panel look without fighting editor theme hard.
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.15, 0.12, 0.08, 0.55)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 2
	sb.content_margin_right = 2
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	add_theme_stylebox_override("panel", sb)
