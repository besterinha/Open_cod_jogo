@tool
class_name VFReportWriter
extends RefCounted

## JSON + HTML reports (Odin-like machine + human review artifacts).

const TOOL_VERSION := "0.13.1"

static func severity_name(severity: int) -> String:
	match severity:
		VFValidationIssue.Severity.INFO:
			return "info"
		VFValidationIssue.Severity.ERROR:
			return "error"
		_:
			return "warning"

static func filter_visible(issues: Array[VFValidationIssue]) -> Array[VFValidationIssue]:
	var visible: Array[VFValidationIssue] = []
	for issue in issues:
		if VFValidationSettings.is_path_ignored(issue.resource_path):
			continue
		if VFValidationSettings.is_path_ignored(issue.related_path):
			continue
		if VFValidationSettings.is_issue_ignored(issue):
			continue
		visible.append(issue)
	return visible

static func count_by_severity(issues: Array[VFValidationIssue]) -> Dictionary:
	var by_severity := {"info": 0, "warning": 0, "error": 0}
	for issue in filter_visible(issues):
		var sev := severity_name(issue.severity)
		by_severity[sev] = int(by_severity.get(sev, 0)) + 1
	return by_severity

static func to_dictionary(issues: Array[VFValidationIssue], profile_name: String = "") -> Dictionary:
	var visible := filter_visible(issues)
	var items: Array = []
	var by_severity := {"info": 0, "warning": 0, "error": 0}
	for issue in visible:
		var sev := severity_name(issue.severity)
		by_severity[sev] = int(by_severity.get(sev, 0)) + 1
		items.append({
			"rule_id": issue.rule_id,
			"severity": sev,
			"message": issue.message,
			"resource_path": issue.resource_path,
			"related_path": issue.related_path,
		})
	var profile := VFValidationSettings.get_active_profile()
	var pname := profile_name
	if pname.is_empty() and profile != null:
		pname = profile.display_name
	return {
		"tool": "godot_validation_flow",
		"version": TOOL_VERSION,
		"profile": pname,
		"issue_count": visible.size(),
		"counts": by_severity,
		"issues": items,
	}

static func to_json_string(issues: Array[VFValidationIssue], profile_name: String = "") -> String:
	return JSON.stringify(to_dictionary(issues, profile_name), "\t")

static func write_json_file(issues: Array[VFValidationIssue], path: String) -> Error:
	return _write_text_file(path, to_json_string(issues))

static func write_html_file(issues: Array[VFValidationIssue], path: String) -> Error:
	return _write_text_file(path, to_html_string(issues))

## Write configured JSON and/or HTML reports.
static func write_configured_reports(issues: Array[VFValidationIssue]) -> void:
	if VFValidationSettings.should_write_json_report():
		var err := write_json_file(issues, VFValidationSettings.get_json_report_path())
		if err != OK:
			push_warning("Validation Flow: JSON report failed (%s)" % error_string(err))
	if VFValidationSettings.should_write_html_report():
		var err2 := write_html_file(issues, VFValidationSettings.get_html_report_path())
		if err2 != OK:
			push_warning("Validation Flow: HTML report failed (%s)" % error_string(err2))

static func to_html_string(issues: Array[VFValidationIssue], profile_name: String = "") -> String:
	var data := to_dictionary(issues, profile_name)
	var counts: Dictionary = data.get("counts", {})
	var rows := PackedStringArray()
	for item in data.get("issues", []):
		if not item is Dictionary:
			continue
		var d: Dictionary = item
		rows.append(
			"<tr class=\"sev-%s\"><td>%s</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>"
			% [
				_esc(str(d.get("severity", ""))),
				_esc(str(d.get("severity", ""))),
				_esc(str(d.get("rule_id", ""))),
				_esc(str(d.get("resource_path", ""))),
				_esc(str(d.get("related_path", ""))),
				_esc(str(d.get("message", ""))),
			]
		)
	var body_rows := "\n".join(rows) if not rows.is_empty() else "<tr><td colspan=\"5\">No issues</td></tr>"
	var head := "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\"/>"
	head += "<title>Validation Flow Report</title><style>"
	head += "body{font-family:ui-sans-serif,system-ui,sans-serif;margin:24px;background:#111;color:#e8e8e8}"
	head += "h1{font-size:1.25rem;margin:0 0 8px}.meta{opacity:.75;margin-bottom:16px}"
	head += "table{border-collapse:collapse;width:100%;font-size:13px}"
	head += "th,td{border:1px solid #333;padding:6px 8px;text-align:left;vertical-align:top}"
	head += "th{background:#1c1c1c}.sev-error td:first-child{color:#f66}"
	head += ".sev-warning td:first-child{color:#fc6}.sev-info td:first-child{color:#6af}"
	head += ".counts span{margin-right:12px}</style></head><body>"
	var meta := (
		"<h1>Godot Validation Flow</h1><div class=\"meta\">v%s · profile: %s · %d issue(s)</div>"
		% [TOOL_VERSION, _esc(str(data.get("profile", ""))), int(data.get("issue_count", 0))]
	)
	var count_line := (
		"<div class=\"counts\"><span>error: %d</span><span>warning: %d</span><span>info: %d</span></div>"
		% [int(counts.get("error", 0)), int(counts.get("warning", 0)), int(counts.get("info", 0))]
	)
	var table := (
		"<table><thead><tr><th>Severity</th><th>Rule</th><th>Resource</th><th>Related</th><th>Message</th></tr></thead><tbody>\n%s\n</tbody></table></body></html>"
		% body_rows
	)
	return head + meta + count_line + table

static func blocking_issue_count(issues: Array[VFValidationIssue], min_severity: int) -> int:
	var n := 0
	for issue in filter_visible(issues):
		if int(issue.severity) >= min_severity:
			n += 1
	return n

## Config enum 0=Any, 1=Warning+, 2=Error only → minimum Severity.
static func min_severity_from_gate_mode(mode: int) -> int:
	match clampi(mode, 0, 2):
		1:
			return VFValidationIssue.Severity.WARNING
		2:
			return VFValidationIssue.Severity.ERROR
		_:
			return VFValidationIssue.Severity.INFO

static func _write_text_file(path: String, text: String) -> Error:
	var abs_path := path
	if path.begins_with("res://") or path.begins_with("user://"):
		abs_path = ProjectSettings.globalize_path(path)
	var dir := abs_path.get_base_dir()
	if not dir.is_empty():
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(abs_path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.close()
	return OK

static func _esc(s: String) -> String:
	return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;")
