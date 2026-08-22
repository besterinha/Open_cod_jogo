extends SceneTree

## Headless validation entry (Odin-like CI).
## Usage:
##   Godot_console.exe --headless --path <project> -s res://addons/godot_validation_flow/cli/run_validation.gd
## Optional user args: --json-out=path  (default: project config json_report_path)
## Exit: 0 = clean, 1 = issues found, 2 = runner error

const VFRuleBootstrap := preload("res://addons/godot_validation_flow/core/rule_bootstrap.gd")
const VFValidationRunner := preload("res://addons/godot_validation_flow/core/validation_runner.gd")
const VFReportWriter := preload("res://addons/godot_validation_flow/core/report_writer.gd")
const VFValidationSettings := preload("res://addons/godot_validation_flow/settings.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var code := 0
	var host := Node.new()
	root.add_child(host)
	var registry = VFRuleBootstrap.build_registry()
	var runner = VFValidationRunner.new(registry)
	var should_abort := func() -> bool: return false
	var report := func(_p: float) -> void: pass
	var found = runner.run_all(host, report, should_abort)
	var visible = VFReportWriter.filter_visible(found)
	print("Godot Validation Flow — %d issue(s)" % visible.size())
	for issue in visible:
		print(
			"[%s] %s | %s | %s"
			% [issue.rule_id, issue.resource_path, issue.related_path, issue.message]
		)
	var json_path := _resolve_json_out_path()
	var err: Error = VFReportWriter.write_json_file(found, json_path)
	if err == OK:
		print("JSON report: %s" % json_path)
	else:
		push_warning("Validation Flow: failed to write JSON report (%s)" % error_string(err))
	if VFValidationSettings.should_write_html_report():
		var html_path := json_path
		if html_path.get_extension().to_lower() == "json":
			html_path = html_path.get_basename() + ".html"
		else:
			html_path = html_path + ".html"
		var err_h: Error = VFReportWriter.write_html_file(found, html_path)
		if err_h == OK:
			print("HTML report: %s" % html_path)
	code = 0 if visible.is_empty() else 1
	host.queue_free()
	quit(code)

func _resolve_json_out_path() -> String:
	for arg in OS.get_cmdline_user_args():
		var a := str(arg)
		if a.begins_with("--json-out="):
			return a.substr("--json-out=".length()).strip_edges()
	return VFValidationSettings.get_json_report_path()
