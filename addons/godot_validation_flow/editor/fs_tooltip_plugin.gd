@tool
extends EditorResourceTooltipPlugin

## Append Validation summary to FileSystem resource tooltips.

var _index: VFIssueIndex

func setup(index: VFIssueIndex) -> void:
	_index = index

func _handles(_type: String) -> bool:
	return _index != null

func _make_tooltip_for_path(path: String, _metadata: Dictionary, base: Control) -> Control:
	if _index == null:
		return base
	var issues := _index.for_path(path)
	if issues.is_empty():
		return base
	var box := VBoxContainer.new()
	if base != null:
		base.reparent(box)
	var label := Label.new()
	var counts := {"error": 0, "warning": 0, "info": 0}
	for issue in issues:
		var sev := VFReportWriter.severity_name(issue.severity)
		counts[sev] = int(counts.get(sev, 0)) + 1
	var head := "Validation: %d issue(s)" % issues.size()
	var detail := issues[0].message
	if issues.size() > 1:
		detail += " (+%d more)" % (issues.size() - 1)
	label.text = "%s\n%s" % [head, detail]
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(220, 0)
	box.add_child(label)
	return box
