@tool
extends EditorPlugin

## Godot Validation Flow — validation workbench.

const PANEL_TITLE := "Validation"
const MENU_SCAN := "Validation Flow/Run Validation"
const MENU_FOCUS := "Validation Flow/Focus Panel"
const SETTINGS_RELOAD_DELAY_SEC := 0.4

const DockScene := preload("res://addons/godot_validation_flow/ui/dock.tscn")
const BrandIcon := preload("res://addons/godot_validation_flow/icon.png")
const ExportGateScript := preload("res://addons/godot_validation_flow/export/export_gate_plugin.gd")
const IssueIndexScript := preload("res://addons/godot_validation_flow/core/issue_index.gd")
const InspectorPluginScript := preload("res://addons/godot_validation_flow/editor/inspector_plugin.gd")
const FsTooltipPluginScript := preload("res://addons/godot_validation_flow/editor/fs_tooltip_plugin.gd")
const SceneBadgeScript := preload("res://addons/godot_validation_flow/ui/scene_badge.gd")

var _panel: Control
var _panel_button: Button
var _scene_badges: Array[Button] = []
var _scene_badge_containers: Array[int] = []
var _fs: EditorFileSystem
var _registry: VFValidationRegistry
var _runner: VFValidationRunner
var _issue_index: VFIssueIndex
var _inspector_plugin: EditorInspectorPlugin
var _fs_tooltip: EditorResourceTooltipPlugin
var _settings_reload_timer: Timer
var _watched_config: Resource
var _export_gate: EditorExportPlugin

func _enter_tree() -> void:
	VFValidationSettings.ensure_project_settings()
	_registry = VFRuleBootstrap.build_registry()
	_runner = VFValidationRunner.new(_registry)
	_issue_index = IssueIndexScript.new()

	_panel = DockScene.instantiate()
	_panel.issue_count_changed.connect(_on_issue_count_changed)
	_panel_button = add_control_to_bottom_panel(_panel, PANEL_TITLE)
	_panel.setup(self, _runner, _registry, _issue_index)
	_on_issue_count_changed(_panel.get_issue_count())

	# 2D / 3D editor menu bars (next to View) — not the main play toolbar.
	_add_scene_badge(CONTAINER_CANVAS_EDITOR_MENU)
	_add_scene_badge(CONTAINER_SPATIAL_EDITOR_MENU)

	_inspector_plugin = InspectorPluginScript.new()
	_inspector_plugin.setup(
		_issue_index,
		Callable(self, "_open_issue_from_inspector"),
		Callable(self, "_on_menu_focus")
	)
	add_inspector_plugin(_inspector_plugin)

	_fs_tooltip = FsTooltipPluginScript.new()
	_fs_tooltip.setup(_issue_index)
	EditorInterface.get_file_system_dock().add_resource_tooltip_plugin(_fs_tooltip)

	add_tool_menu_item(MENU_SCAN, _on_menu_scan)
	add_tool_menu_item(MENU_FOCUS, _on_menu_focus)

	_export_gate = ExportGateScript.new()
	add_export_plugin(_export_gate)

	_fs = EditorInterface.get_resource_filesystem()
	if _fs:
		_fs.filesystem_changed.connect(_on_filesystem_changed)
		if _fs.has_signal("resources_reimported"):
			_fs.resources_reimported.connect(_on_resources_reimported)

	_settings_reload_timer = Timer.new()
	_settings_reload_timer.one_shot = true
	_settings_reload_timer.wait_time = SETTINGS_RELOAD_DELAY_SEC
	_settings_reload_timer.timeout.connect(_on_settings_reload_timeout)
	add_child(_settings_reload_timer)

	if ProjectSettings.has_signal("settings_changed"):
		ProjectSettings.settings_changed.connect(_on_project_settings_changed)

	_watch_config_resource()

func _exit_tree() -> void:
	_unwatch_config_resource()

	if ProjectSettings.has_signal("settings_changed"):
		if ProjectSettings.settings_changed.is_connected(_on_project_settings_changed):
			ProjectSettings.settings_changed.disconnect(_on_project_settings_changed)

	if _fs:
		if _fs.filesystem_changed.is_connected(_on_filesystem_changed):
			_fs.filesystem_changed.disconnect(_on_filesystem_changed)
		if _fs.has_signal("resources_reimported"):
			if _fs.resources_reimported.is_connected(_on_resources_reimported):
				_fs.resources_reimported.disconnect(_on_resources_reimported)
	_fs = null

	if _fs_tooltip:
		EditorInterface.get_file_system_dock().remove_resource_tooltip_plugin(_fs_tooltip)
		_fs_tooltip = null

	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null

	if _export_gate:
		remove_export_plugin(_export_gate)
		_export_gate = null

	remove_tool_menu_item(MENU_SCAN)
	remove_tool_menu_item(MENU_FOCUS)

	if _scene_badges.size() > 0:
		for i in _scene_badges.size():
			remove_control_from_container(_scene_badge_containers[i], _scene_badges[i])
			_scene_badges[i].queue_free()
		_scene_badges.clear()
		_scene_badge_containers.clear()

	if _panel:
		if _panel.issue_count_changed.is_connected(_on_issue_count_changed):
			_panel.issue_count_changed.disconnect(_on_issue_count_changed)
		remove_control_from_bottom_panel(_panel)
		_panel.queue_free()
		_panel = null
		_panel_button = null

	_settings_reload_timer = null
	_runner = null
	_registry = null
	_issue_index = null

## Odin-like Play gate: return false to prevent running the project.
func _build() -> bool:
	if not VFValidationSettings.is_play_gate_enabled():
		return true
	reload_registry()
	if _runner == null:
		_runner = VFValidationRunner.new(_registry)
	var noop := func(_p: float) -> void: pass
	var never := func() -> bool: return false
	var found: Array[VFValidationIssue] = _runner.run_all(null, noop, never)
	VFReportWriter.write_configured_reports(found)
	var min_sev := VFReportWriter.min_severity_from_gate_mode(
		VFValidationSettings.get_play_gate_severity_mode()
	)
	var blocking := VFReportWriter.blocking_issue_count(found, min_sev)
	if blocking <= 0:
		return true
	push_error(
		"Validation Flow: Play blocked — %d issue(s) (threshold=%s). Open Validation panel or see %s"
		% [
			blocking,
			VFReportWriter.severity_name(min_sev),
			VFValidationSettings.get_json_report_path(),
		]
	)
	if _panel:
		_panel.apply_gate_results(found)
		make_bottom_panel_item_visible(_panel)
	return false

## Rebuild rule list from current ProjectValidationRules / ProjectSettings (same registry object).
func reload_registry() -> void:
	if _registry == null:
		return
	VFRuleBootstrap.populate_registry(_registry)
	_watch_config_resource()

func _watch_config_resource() -> void:
	var cfg: Resource = VFValidationSettings.get_project_config()
	if cfg == _watched_config:
		return
	_unwatch_config_resource()
	_watched_config = cfg
	if _watched_config != null and not _watched_config.changed.is_connected(_on_config_resource_changed):
		_watched_config.changed.connect(_on_config_resource_changed)

func _unwatch_config_resource() -> void:
	if _watched_config != null and _watched_config.changed.is_connected(_on_config_resource_changed):
		_watched_config.changed.disconnect(_on_config_resource_changed)
	_watched_config = null

func _on_config_resource_changed() -> void:
	if _settings_reload_timer == null:
		return
	_settings_reload_timer.start(SETTINGS_RELOAD_DELAY_SEC)

func _shortcut_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var k := event as InputEventKey
	if k.ctrl_pressed and k.alt_pressed and not k.shift_pressed and k.keycode == KEY_D:
		make_bottom_panel_item_visible(_panel)
		_panel.scan_now(true, true)
		get_viewport().set_input_as_handled()
	elif k.ctrl_pressed and k.alt_pressed and k.shift_pressed and k.keycode == KEY_D:
		make_bottom_panel_item_visible(_panel)
		_panel.focus_list()
		get_viewport().set_input_as_handled()

func _add_scene_badge(container: int) -> void:
	var badge: Button = SceneBadgeScript.new()
	badge.setup(_issue_index)
	badge.focus_scene_requested.connect(_on_scene_badge_pressed)
	add_control_to_container(container, badge)
	_scene_badges.append(badge)
	_scene_badge_containers.append(container)

func _on_menu_scan() -> void:
	make_bottom_panel_item_visible(_panel)
	_panel.scan_now(true, true)

func _on_menu_focus() -> void:
	make_bottom_panel_item_visible(_panel)
	if _panel:
		_panel.focus_list()

func _on_scene_badge_pressed() -> void:
	make_bottom_panel_item_visible(_panel)
	if _panel and _panel.has_method("focus_current_scene_issues"):
		_panel.focus_current_scene_issues()

func _open_issue_from_inspector(issue: VFValidationIssue) -> void:
	if _panel == null or issue == null:
		return
	make_bottom_panel_item_visible(_panel)
	_panel.open_issue(issue)

func _on_filesystem_changed() -> void:
	if _panel and VFValidationSettings.is_auto_scan_enabled():
		_panel.schedule_auto_scan()

func _on_resources_reimported(resources: PackedStringArray) -> void:
	if _is_config_among(resources):
		reload_registry()
		if _panel:
			_panel.schedule_config_rescan()

func _on_project_settings_changed() -> void:
	if _settings_reload_timer == null:
		return
	_settings_reload_timer.start(SETTINGS_RELOAD_DELAY_SEC)

func _on_settings_reload_timeout() -> void:
	reload_registry()
	if _panel:
		_panel.schedule_config_rescan()

func _is_config_among(resources: PackedStringArray) -> bool:
	var cfg_path := str(
		ProjectSettings.get_setting(
			VFValidationSettings.PS_CONFIG_PATH,
			VFValidationSettings.DEFAULT_CONFIG_PATH
		)
	).strip_edges()
	if cfg_path.is_empty():
		cfg_path = VFValidationSettings.DEFAULT_CONFIG_PATH
	for path in resources:
		if str(path) == cfg_path:
			return true
		for adv in VFValidationSettings.get_advanced_custom_rule_definition_paths():
			if str(path) == str(adv).strip_edges():
				return true
	return false

func _on_issue_count_changed(count: int) -> void:
	for badge in _scene_badges:
		if badge and badge.has_method("refresh"):
			badge.refresh()
	if _panel_button == null:
		return
	var errors := 0
	var warnings := 0
	var infos := 0
	if _issue_index != null:
		var c := _issue_index.counts()
		errors = int(c.get("error", 0))
		warnings = int(c.get("warning", 0))
		infos = int(c.get("info", 0))
		count = _issue_index.total()
	if count <= 0:
		_panel_button.text = PANEL_TITLE
		_panel_button.icon = BrandIcon
		return
	var label := PANEL_TITLE
	if errors > 0:
		label = "%s · E%d" % [PANEL_TITLE, errors]
		if warnings > 0:
			label += " W%d" % warnings
		_panel_button.icon = _editor_icon("StatusError")
	elif warnings > 0:
		label = "%s · W%d" % [PANEL_TITLE, warnings]
		if infos > 0:
			label += " I%d" % infos
		_panel_button.icon = _editor_icon("StatusWarning")
	else:
		label = "%s · I%d" % [PANEL_TITLE, infos]
		_panel_button.icon = _editor_icon("StatusWarning")
	_panel_button.text = label

func _editor_icon(name: String) -> Texture2D:
	var base := EditorInterface.get_base_control()
	if base.has_theme_icon(name, "EditorIcons"):
		return base.get_theme_icon(name, "EditorIcons")
	return BrandIcon
