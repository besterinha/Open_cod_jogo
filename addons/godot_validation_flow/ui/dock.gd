@tool
extends MarginContainer

## Validation Flow results dock — group modes, ignores, full + incremental scans.

signal issue_count_changed(count: int)

const AUTO_SCAN_DELAY_SEC := 1.2

var _plugin: EditorPlugin
var _runner: VFValidationRunner
var _registry: VFValidationRegistry
var _issue_index: VFIssueIndex
var _issues: Array[VFValidationIssue] = []
var _filter: String = ""
var _wired := false
var _scanning := false
var _scan_gen := 0
var _auto_timer: Timer
var _group_mode: String = VFValidationSettings.GROUP_BY_RULE
var _pending_config_rescan := false
var _profile_paths: PackedStringArray = []

var _pending_select_fp: String = ""
var _selection_refresh_connected := false
var _has_scanned := false
var _context_group: Dictionary = {}

@onready var _toolbar_shell: PanelContainer = %ToolbarShell
@onready var _column_header: PanelContainer = %ColumnHeader
@onready var _footer_shell: PanelContainer = %FooterShell
@onready var _header_split: HSplitContainer = %HeaderSplit
@onready var _header_split2: HSplitContainer = %HeaderSplit2
@onready var _header_split3: HSplitContainer = %HeaderSplit3
@onready var _subject_header: HBoxContainer = %SubjectHeader
@onready var _hdr_subject: Label = %HdrSubject
@onready var _hdr_detail: Label = %HdrDetail
@onready var _hdr_severity: Label = %HdrSeverity
@onready var _hdr_actions: Label = %HdrActions
@onready var _table_filter_btn: MenuButton = %TableFilterButton
@onready var _filter_edit: LineEdit = %FilterEdit
@onready var _tree: Tree = %IssueTree
@onready var _empty: CenterContainer = %EmptyState
@onready var _empty_title: Label = %EmptyTitle
@onready var _empty_body: Label = %EmptyBody
@onready var _detail: Label = %DetailLabel
@onready var _btn_scan: Button = %ScanButton
@onready var _brand_icon: TextureRect = %BrandIcon
@onready var _progress: ProgressBar = %ProgressBar
@onready var _empty_scan: Button = %EmptyScanButton
@onready var _empty_report: Button = %EmptyReportButton
@onready var _auto_scan: CheckButton = %AutoScanToggle
@onready var _sev_error_toggle: Button = %SevErrorToggle
@onready var _sev_warn_toggle: Button = %SevWarnToggle
@onready var _sev_info_toggle: Button = %SevInfoToggle
@onready var _current_scene_toggle: CheckButton = %CurrentSceneToggle

var _context: PopupMenu
var _filter_popup: PopupMenu
var _syncing_columns := false
var _filter_menu_wired := false
var _column_splits_initialized := false

const COL_SUBJECT := 0
const COL_DETAIL := 1
const COL_SEVERITY := 2
const COL_ACTIONS := 3
const BTN_REVEAL := 0
const BTN_COPY := 1

const MENU_GROUP_RULE := 100
const MENU_GROUP_MISSING := 101
const MENU_PROFILE_BASE := 200
const MENU_RULE_ALL := 400
const MENU_RULE_BASE := 401

func setup(
	plugin: EditorPlugin,
	runner: VFValidationRunner,
	registry: VFValidationRegistry,
	issue_index: VFIssueIndex = null
) -> void:
	_plugin = plugin
	_runner = runner
	_registry = registry
	_issue_index = issue_index
	_group_mode = VFValidationSettings.get_group_mode()
	_ensure_wired()
	_apply_editor_chrome()
	if _auto_scan:
		_auto_scan.set_pressed_no_signal(VFValidationSettings.is_auto_scan_enabled())
	if _current_scene_toggle:
		_current_scene_toggle.set_pressed_no_signal(VFValidationSettings.is_current_scene_only())
	_populate_table_filter_menu()
	_sync_severity_toggles_from_settings()
	_refresh()
	call_deferred("_run_startup_scan")

## Open / navigate an issue from Inspector banner (keeps Scene filter, selects row).
func open_issue(issue: VFValidationIssue) -> void:
	_ensure_wired()
	if issue == null:
		return
	_pending_select_fp = VFValidationSettings.issue_fingerprint(issue)
	_refresh()
	_navigate_to_issue(issue)
	_set_detail(issue.message, true)

## From toolbar Scene badge: force Scene filter on + show this scene's results.
func focus_current_scene_issues() -> void:
	_ensure_wired()
	VFValidationSettings.set_current_scene_only(true)
	if _current_scene_toggle:
		_current_scene_toggle.set_pressed_no_signal(true)
	_refresh()
	focus_list()
	var scene := _edited_scene_path()
	var n := _visible_issues().size()
	if scene.is_empty():
		_set_detail("No edited scene.", true)
	elif n == 0:
		_set_detail("Scene OK — %s" % scene.get_file(), false)
	else:
		_set_detail("Scene filter: %s — %d issue(s)" % [scene.get_file(), n], true)

func get_issue_index() -> VFIssueIndex:
	return _issue_index

func _publish_index() -> void:
	if _issue_index == null:
		return
	_issue_index.set_issues(_issues)

func _run_startup_scan() -> void:
	await scan_now(false, false)

func get_issue_count() -> int:
	return _visible_issues().size()

func focus_list() -> void:
	_ensure_wired()
	if _visible_issues().is_empty():
		_btn_scan.grab_focus()
	else:
		_tree.grab_focus()

## full_pass=false → incremental (Auto). focus_on_issues → steal bottom panel focus.
func scan_now(focus_on_issues: bool = true, full_pass: bool = true) -> void:
	_ensure_wired()
	if _scanning or _runner == null:
		return
	# Hot-reload rules from ProjectValidationRules / ProjectSettings before every run.
	if _plugin != null and _plugin.has_method("reload_registry"):
		_plugin.reload_registry()
	_scanning = true
	_scan_gen += 1
	var gen := _scan_gen
	_btn_scan.disabled = true
	_empty_scan.disabled = true
	_progress.visible = true
	_progress.value = 0
	_set_detail("Running validation…" if full_pass else "Incremental update…", false)

	var should_abort := func() -> bool: return gen != _scan_gen
	var report := func(p: float) -> void:
		if _progress:
			_progress.value = p

	var found: Array[VFValidationIssue]
	if full_pass:
		found = _runner.run_all(self, report, should_abort)
	else:
		found = _runner.run_incremental(self, report, should_abort)
	if gen != _scan_gen:
		return

	_issues = found
	_scanning = false
	_has_scanned = true
	_btn_scan.disabled = false
	_empty_scan.disabled = false
	_progress.visible = false
	VFReportWriter.write_configured_reports(found)
	_publish_index()
	_populate_table_filter_menu()
	_refresh()
	var visible_n := _visible_issues().size()
	if visible_n == 0:
		_set_detail("No validation issues found.", false)
	else:
		_set_detail(_summary_counts(_issues), true)
		if focus_on_issues and _plugin:
			_plugin.make_bottom_panel_item_visible(self)

## Used by Play/export gates to show the same result set in the dock.
func apply_gate_results(found: Array[VFValidationIssue]) -> void:
	_ensure_wired()
	_issues = found
	_has_scanned = true
	_publish_index()
	_populate_table_filter_menu()
	_refresh()
	issue_count_changed.emit(get_issue_count())
	var visible_n := _visible_issues().size()
	_set_detail("Gate: %s" % _summary_counts(_issues), visible_n > 0)

## After Project Settings / config .tres change — quiet full rescan (no focus steal).
func schedule_config_rescan() -> void:
	_ensure_wired()
	_populate_table_filter_menu()
	if _auto_timer == null:
		return
	_pending_config_rescan = true
	_auto_timer.start(AUTO_SCAN_DELAY_SEC)

func schedule_auto_scan() -> void:
	_ensure_wired()
	if _auto_timer == null:
		return
	_pending_config_rescan = false
	_auto_timer.start(AUTO_SCAN_DELAY_SEC)

func _ready() -> void:
	_ensure_wired()

func _ensure_wired() -> void:
	if _wired or _tree == null:
		return
	_wired = true

	_tree.hide_root = true
	_tree.columns = 4
	_tree.set_column_titles_visible(false)
	_tree.set_column_expand(COL_SUBJECT, false)
	_tree.set_column_expand(COL_DETAIL, false)
	_tree.set_column_expand(COL_SEVERITY, false)
	_tree.set_column_expand(COL_ACTIONS, false)
	_tree.allow_rmb_select = true
	_tree.select_mode = Tree.SELECT_ROW

	_context = PopupMenu.new()
	add_child(_context)
	_context.id_pressed.connect(_on_context_id)

	_auto_timer = Timer.new()
	_auto_timer.one_shot = true
	_auto_timer.timeout.connect(_on_auto_timer)
	add_child(_auto_timer)

	_btn_scan.pressed.connect(_on_validate_pressed)
	_empty_scan.pressed.connect(_on_validate_pressed)
	if _empty_report:
		_empty_report.pressed.connect(_open_html_report)
	_filter_edit.text_changed.connect(_on_filter_changed)
	_tree.item_activated.connect(_open_selected)
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_mouse_selected.connect(_on_item_mouse_selected)
	_tree.button_clicked.connect(_on_tree_button_clicked)
	_tree.gui_input.connect(_on_tree_gui_input)
	_tree.resized.connect(_ensure_default_column_layout)
	if _header_split:
		_header_split.dragged.connect(_on_header_dragged)
	if _header_split2:
		_header_split2.dragged.connect(_on_header_dragged)
	if _header_split3:
		_header_split3.dragged.connect(_on_header_dragged)
	call_deferred("_ensure_default_column_layout")
	if _auto_scan:
		_auto_scan.toggled.connect(_on_auto_scan_toggled)
	if _sev_error_toggle:
		_sev_error_toggle.toggled.connect(_on_sev_error_toggled)
	if _sev_warn_toggle:
		_sev_warn_toggle.toggled.connect(_on_sev_warn_toggled)
	if _sev_info_toggle:
		_sev_info_toggle.toggled.connect(_on_sev_info_toggled)
	if _current_scene_toggle:
		_current_scene_toggle.toggled.connect(_on_current_scene_toggled)
	_wire_table_filter_menu()
	if not _selection_refresh_connected:
		var sel := EditorInterface.get_selection()
		if sel and not sel.selection_changed.is_connected(_on_editor_selection_changed):
			sel.selection_changed.connect(_on_editor_selection_changed)
			_selection_refresh_connected = true

func _on_validate_pressed() -> void:
	scan_now(true, true)

func _on_auto_timer() -> void:
	if _pending_config_rescan:
		_pending_config_rescan = false
		scan_now(false, true)
	else:
		scan_now(false, false)

func _apply_editor_chrome() -> void:
	if _btn_scan == null:
		return
	var base := EditorInterface.get_base_control()
	_apply_chrome_panels(base)
	if _brand_icon:
		var brand := load("res://addons/godot_validation_flow/icon.png") as Texture2D
		if brand:
			_brand_icon.texture = brand
			_brand_icon.custom_minimum_size = Vector2(22, 22)
			_brand_icon.tooltip_text = "Godot Validation Flow"
	_set_btn(_btn_scan, base, "Play", "Full validation (Ctrl+Alt+D)", true)
	_btn_scan.text = "Validate"
	_set_btn(_empty_scan, base, "Play", "Full validation (Ctrl+Alt+D)", true)
	_empty_scan.text = "Run Validation"
	if _empty_report:
		_set_btn(_empty_report, base, "FileList", "Open last HTML validation report", true)
		_empty_report.text = "Open HTML report"
	_filter_edit.right_icon = base.get_theme_icon("Search", "EditorIcons")
	if _table_filter_btn:
		var icon_name := "Sort"
		if not base.has_theme_icon(icon_name, "EditorIcons"):
			icon_name = "AnimationFilter"
		if not base.has_theme_icon(icon_name, "EditorIcons"):
			icon_name = "GuiTabMenuHl"
		if base.has_theme_icon(icon_name, "EditorIcons"):
			_table_filter_btn.icon = base.get_theme_icon(icon_name, "EditorIcons")
		_table_filter_btn.text = ""
		_table_filter_btn.flat = true
		_table_filter_btn.tooltip_text = "List filters — profile, group, rule"
	if _auto_scan:
		_auto_scan.tooltip_text = "Debounced incremental re-check after filesystem changes"
		_auto_scan.text = "Auto"
	if _current_scene_toggle:
		_current_scene_toggle.tooltip_text = "Only show issues whose resource is the currently edited scene"
		_current_scene_toggle.text = "Scene"
	_style_severity_toggles(base)
	_apply_column_titles()
	call_deferred("_ensure_default_column_layout")

func _apply_chrome_panels(base: Control) -> void:
	var dark := Color(0.11, 0.12, 0.14, 1.0)
	if base.has_theme_color("dark_color_1", "Editor"):
		dark = base.get_theme_color("dark_color_1", "Editor")
	elif base.has_theme_color("base_color", "Editor"):
		dark = base.get_theme_color("base_color", "Editor").darkened(0.22)
	var mid := dark.lightened(0.04)
	var border := dark.lightened(0.1)
	if base.has_theme_color("dark_color_2", "Editor"):
		border = base.get_theme_color("dark_color_2", "Editor")
	_style_panel(_toolbar_shell, dark, border, 4)
	_style_panel(_column_header, mid.darkened(0.06), border, 0)
	_style_panel(_footer_shell, dark, border, 0)
	var muted := Color(0.75, 0.78, 0.82, 1.0)
	if base.has_theme_color("font_color", "Editor"):
		muted = base.get_theme_color("font_color", "Editor")
		muted.a = 0.75
	for lbl in [_hdr_subject, _hdr_detail, _hdr_severity, _hdr_actions]:
		if lbl:
			lbl.add_theme_color_override("font_color", muted)

func _style_panel(panel: PanelContainer, bg: Color, border: Color, radius: int) -> void:
	if panel == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(1 if radius > 0 else 0)
	if radius == 0:
		sb.border_width_bottom = 1
		sb.border_color = border
	sb.content_margin_left = 0
	sb.content_margin_top = 0
	sb.content_margin_right = 0
	sb.content_margin_bottom = 0
	panel.add_theme_stylebox_override("panel", sb)

func _on_header_dragged(_offset: int) -> void:
	_column_splits_initialized = true
	_sync_columns_from_header()

## First layout: Subject / Detail equal width; Sev / Actions stay compact.
func _ensure_default_column_layout() -> void:
	if _header_split == null or _header_split2 == null or _header_split3 == null or _column_header == null:
		return
	if not _column_splits_initialized:
		var total := int(_column_header.size.x)
		if total >= 280:
			const SEV_W := 48
			const ACT_W := 72
			const FIXED := SEV_W + ACT_W + 16
			var half := maxi(120, int((total - FIXED) / 2.0))
			_header_split.split_offset = half
			_header_split2.split_offset = half
			_header_split3.split_offset = SEV_W
			_column_splits_initialized = true
	_sync_columns_from_header()

func _sync_columns_from_header() -> void:
	if _syncing_columns or _tree == null:
		return
	if _subject_header == null or _hdr_detail == null or _hdr_severity == null or _hdr_actions == null:
		return
	_syncing_columns = true
	var w_sub := maxi(80, int(_subject_header.size.x))
	var w_det := maxi(80, int(_hdr_detail.size.x))
	var w_sev := maxi(36, int(_hdr_severity.size.x))
	var w_act := maxi(56, int(_hdr_actions.size.x))
	_tree.set_column_custom_minimum_width(COL_SUBJECT, w_sub)
	_tree.set_column_custom_minimum_width(COL_DETAIL, w_det)
	_tree.set_column_custom_minimum_width(COL_SEVERITY, w_sev)
	_tree.set_column_custom_minimum_width(COL_ACTIONS, w_act)
	_syncing_columns = false

func _wire_table_filter_menu() -> void:
	if _filter_menu_wired or _table_filter_btn == null:
		return
	_filter_menu_wired = true
	_filter_popup = _table_filter_btn.get_popup()
	_filter_popup.id_pressed.connect(_on_table_filter_id)
	_filter_popup.about_to_popup.connect(_populate_table_filter_menu)

func _populate_table_filter_menu() -> void:
	if _table_filter_btn == null:
		return
	if _filter_popup == null:
		_filter_popup = _table_filter_btn.get_popup()
	_profile_paths = VFValidationSettings.list_profile_paths()
	var current_profile := VFValidationSettings.get_profile_override_path()
	var rule_filter := VFValidationSettings.get_rule_filter()
	_filter_popup.clear()

	_filter_popup.add_separator("Profile")
	if _profile_paths.is_empty():
		var idx := _filter_popup.get_item_count()
		_filter_popup.add_radio_check_item("Default", MENU_PROFILE_BASE)
		_filter_popup.set_item_metadata(idx, "")
		_filter_popup.set_item_checked(idx, true)
	else:
		for i in _profile_paths.size():
			var path := _profile_paths[i]
			var label := path.get_file().get_basename()
			var res: Resource = load(path) as Resource
			if res is VFValidationProfile:
				var dn := (res as VFValidationProfile).display_name.strip_edges()
				if not dn.is_empty():
					label = dn
			var id := MENU_PROFILE_BASE + i
			var item_i := _filter_popup.get_item_count()
			_filter_popup.add_radio_check_item(label, id)
			_filter_popup.set_item_metadata(item_i, path)
			var checked := (
				path == current_profile
				or (current_profile.is_empty() and path == VFValidationSettings.DEFAULT_PROFILE_PATH)
			)
			_filter_popup.set_item_checked(item_i, checked)

	_filter_popup.add_separator("Group")
	var group_rule_i := _filter_popup.get_item_count()
	_filter_popup.add_radio_check_item("Group by Rule", MENU_GROUP_RULE)
	_filter_popup.set_item_checked(group_rule_i, _group_mode != VFValidationSettings.GROUP_BY_MISSING)
	var group_missing_i := _filter_popup.get_item_count()
	_filter_popup.add_radio_check_item("Group by Missing", MENU_GROUP_MISSING)
	_filter_popup.set_item_checked(group_missing_i, _group_mode == VFValidationSettings.GROUP_BY_MISSING)

	_filter_popup.add_separator("Rule")
	var all_i := _filter_popup.get_item_count()
	_filter_popup.add_radio_check_item("All rules", MENU_RULE_ALL)
	_filter_popup.set_item_checked(all_i, rule_filter.is_empty())
	if _registry:
		var ri := 0
		for rule in _registry.get_rules():
			var item_i := _filter_popup.get_item_count()
			_filter_popup.add_radio_check_item(rule.get_display_name(), MENU_RULE_BASE + ri)
			_filter_popup.set_item_metadata(item_i, rule.get_id())
			_filter_popup.set_item_checked(item_i, rule.get_id() == rule_filter)
			ri += 1

func _on_table_filter_id(id: int) -> void:
	if id == MENU_GROUP_RULE:
		_on_group_mode_selected(0)
		return
	if id == MENU_GROUP_MISSING:
		_on_group_mode_selected(1)
		return
	if id == MENU_RULE_ALL:
		VFValidationSettings.set_rule_filter("")
		_refresh()
		return
	if id >= MENU_RULE_BASE:
		var rule_meta: Variant = _filter_menu_metadata_for_id(id)
		VFValidationSettings.set_rule_filter(str(rule_meta))
		_refresh()
		return
	if id >= MENU_PROFILE_BASE:
		var path := str(_filter_menu_metadata_for_id(id))
		VFValidationSettings.set_profile_override_path(path)
		if _plugin != null and _plugin.has_method("reload_registry"):
			_plugin.reload_registry()
		scan_now(false, true)

func _filter_menu_metadata_for_id(id: int) -> Variant:
	if _filter_popup == null:
		return ""
	for i in _filter_popup.item_count:
		if _filter_popup.get_item_id(i) == id:
			return _filter_popup.get_item_metadata(i)
	return ""

func _style_severity_toggles(base: Control) -> void:
	_style_sev_toggle(_sev_error_toggle, base, "StatusError", "Show errors")
	_style_sev_toggle(_sev_warn_toggle, base, "StatusWarning", "Show warnings")
	_style_sev_toggle(_sev_info_toggle, base, "NodeInfo", "Show info")

func _sev_toggle_stylebox(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 5
	sb.content_margin_right = 6
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	return sb

func _style_sev_toggle(btn: Button, base: Control, icon_name: String, tip: String) -> void:
	if btn == null:
		return
	btn.toggle_mode = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = tip
	btn.modulate = Color.WHITE
	btn.flat = false
	btn.theme_type_variation = ""
	# Clear backgrounds mark ON vs OFF: pressed = enabled filter.
	btn.add_theme_stylebox_override("normal", _sev_toggle_stylebox(Color(0, 0, 0, 0)))
	btn.add_theme_stylebox_override("hover", _sev_toggle_stylebox(Color(1, 1, 1, 0.08)))
	btn.add_theme_stylebox_override("pressed", _sev_toggle_stylebox(Color(1, 1, 1, 0.18)))
	btn.add_theme_stylebox_override("hover_pressed", _sev_toggle_stylebox(Color(1, 1, 1, 0.24)))
	btn.add_theme_stylebox_override("disabled", _sev_toggle_stylebox(Color(0, 0, 0, 0)))
	btn.add_theme_stylebox_override("focus", _sev_toggle_stylebox(Color(0, 0, 0, 0)))
	# ON: full icon/text. OFF: dimmed so state is obvious even without hover.
	btn.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.45))
	btn.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.7))
	btn.add_theme_color_override("icon_pressed_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("icon_hover_pressed_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.25))
	btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 0.55))
	btn.add_theme_color_override("font_hover_color", Color(0.85, 0.85, 0.85, 0.8))
	btn.add_theme_color_override("font_pressed_color", Color(0.92, 0.92, 0.92, 1))
	btn.add_theme_color_override("font_hover_pressed_color", Color(1, 1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6, 0.35))
	if base.has_theme_icon(icon_name, "EditorIcons"):
		btn.icon = base.get_theme_icon(icon_name, "EditorIcons")

func _sync_severity_toggles_from_settings() -> void:
	if _sev_error_toggle:
		_sev_error_toggle.set_pressed_no_signal(
			VFValidationSettings.is_severity_shown(VFValidationIssue.Severity.ERROR)
		)
	if _sev_warn_toggle:
		_sev_warn_toggle.set_pressed_no_signal(
			VFValidationSettings.is_severity_shown(VFValidationIssue.Severity.WARNING)
		)
	if _sev_info_toggle:
		_sev_info_toggle.set_pressed_no_signal(
			VFValidationSettings.is_severity_shown(VFValidationIssue.Severity.INFO)
		)

func _update_severity_toggle_counts() -> void:
	var counts := {"error": 0, "warning": 0, "info": 0}
	for issue in _issues_for_severity_counts():
		var key := VFReportWriter.severity_name(issue.severity)
		counts[key] = int(counts.get(key, 0)) + 1
	if _sev_error_toggle:
		_sev_error_toggle.text = str(int(counts.get("error", 0)))
	if _sev_warn_toggle:
		_sev_warn_toggle.text = str(int(counts.get("warning", 0)))
	if _sev_info_toggle:
		_sev_info_toggle.text = str(int(counts.get("info", 0)))

## Counts ignore the severity toggles so each button shows how many exist.
func _issues_for_severity_counts() -> Array[VFValidationIssue]:
	var out: Array[VFValidationIssue] = []
	var rule_filter := VFValidationSettings.get_rule_filter()
	var scene_only := VFValidationSettings.is_current_scene_only()
	for issue in _issues:
		if VFValidationSettings.is_path_ignored(issue.resource_path):
			continue
		if VFValidationSettings.is_path_ignored(issue.related_path):
			continue
		if VFValidationSettings.is_issue_ignored(issue):
			continue
		if not rule_filter.is_empty() and issue.rule_id != rule_filter:
			continue
		if scene_only and not _issue_matches_current_scene(issue):
			continue
		if not _passes_filter(issue):
			continue
		out.append(issue)
	return out

func _on_sev_error_toggled(pressed: bool) -> void:
	VFValidationSettings.set_severity_shown(VFValidationIssue.Severity.ERROR, pressed)
	_refresh()

func _on_sev_warn_toggled(pressed: bool) -> void:
	VFValidationSettings.set_severity_shown(VFValidationIssue.Severity.WARNING, pressed)
	_refresh()

func _on_sev_info_toggled(pressed: bool) -> void:
	VFValidationSettings.set_severity_shown(VFValidationIssue.Severity.INFO, pressed)
	_refresh()

func _apply_column_titles() -> void:
	if _hdr_subject == null:
		return
	if _group_mode == VFValidationSettings.GROUP_BY_MISSING:
		_hdr_subject.text = "Missing / referrer"
	else:
		_hdr_subject.text = "Subject"
	_hdr_detail.text = "Detail"
	_hdr_severity.text = "Sev"
	_hdr_actions.text = "Actions"

func _set_btn(btn: Button, base: Control, icon_name: String, tip: String, with_text: bool) -> void:
	btn.icon = base.get_theme_icon(icon_name, "EditorIcons")
	btn.tooltip_text = tip
	btn.flat = true
	if not with_text:
		btn.text = ""

func _on_auto_scan_toggled(pressed: bool) -> void:
	VFValidationSettings.set_auto_scan_enabled(pressed)

func _on_group_mode_selected(index: int) -> void:
	_group_mode = (
		VFValidationSettings.GROUP_BY_MISSING
		if index == 1
		else VFValidationSettings.GROUP_BY_RULE
	)
	VFValidationSettings.set_group_mode(_group_mode)
	_apply_column_titles()
	_refresh()

func _on_filter_changed(text: String) -> void:
	_filter = text.strip_edges().to_lower()
	_refresh()

func _on_current_scene_toggled(pressed: bool) -> void:
	VFValidationSettings.set_current_scene_only(pressed)
	_refresh()

func _on_editor_selection_changed() -> void:
	if VFValidationSettings.is_current_scene_only():
		_refresh()

func _edited_scene_path() -> String:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return ""
	return root.scene_file_path.strip_edges()

func _issue_matches_current_scene(issue: VFValidationIssue) -> bool:
	var scene := _edited_scene_path()
	if scene.is_empty():
		return false
	if issue.resource_path == scene:
		return true
	# Related path pointing at the open scene (e.g. export coverage reverse).
	if issue.related_path == scene:
		return true
	return false

func _visible_issues() -> Array[VFValidationIssue]:
	var out: Array[VFValidationIssue] = []
	var rule_filter := VFValidationSettings.get_rule_filter()
	var scene_only := VFValidationSettings.is_current_scene_only()
	for issue in _issues:
		if VFValidationSettings.is_path_ignored(issue.resource_path):
			continue
		if VFValidationSettings.is_path_ignored(issue.related_path):
			continue
		if VFValidationSettings.is_issue_ignored(issue):
			continue
		if not VFValidationSettings.issue_passes_severity_filter(issue):
			continue
		if not rule_filter.is_empty() and issue.rule_id != rule_filter:
			continue
		if scene_only and not _issue_matches_current_scene(issue):
			continue
		if not _passes_filter(issue):
			continue
		out.append(issue)
	return out

func _select_fingerprint(fp: String) -> void:
	if fp.is_empty() or _tree == null:
		return
	var root := _tree.get_root()
	if root == null:
		return
	var hit := _find_item_by_fingerprint(root, fp)
	if hit == null:
		return
	hit.select(0)
	_tree.scroll_to_item(hit)
	_on_item_selected()

func _find_item_by_fingerprint(item: TreeItem, fp: String) -> TreeItem:
	var meta = item.get_metadata(COL_SUBJECT)
	if typeof(meta) == TYPE_INT:
		var idx := int(meta)
		if idx >= 0 and idx < _issues.size():
			if VFValidationSettings.issue_fingerprint(_issues[idx]) == fp:
				return item
	var child := item.get_first_child()
	while child != null:
		var found := _find_item_by_fingerprint(child, fp)
		if found != null:
			return found
		child = child.get_next()
	return null

func _refresh() -> void:
	if _tree == null:
		return
	_tree.clear()
	var base := EditorInterface.get_base_control()
	var warn_color := Color(1, 0.75, 0.35)
	if base.has_theme_color("warning_color", "Editor"):
		warn_color = base.get_theme_color("warning_color", "Editor")
	var error_color := Color(1, 0.45, 0.45)
	if base.has_theme_color("error_color", "Editor"):
		error_color = base.get_theme_color("error_color", "Editor")
	var info_color := Color(0.55, 0.75, 1.0)
	if base.has_theme_color("font_color", "Editor"):
		info_color = base.get_theme_color("font_color", "Editor")
		info_color.a = 0.85

	var visible_list := _visible_issues()
	# Map fingerprint -> index in _issues for metadata
	var index_of: Dictionary = {}
	for i in _issues.size():
		index_of[VFValidationSettings.issue_fingerprint(_issues[i])] = i

	var root := _tree.create_item()
	var visible := 0
	if _group_mode == VFValidationSettings.GROUP_BY_MISSING:
		visible = _fill_tree_by_missing(root, visible_list, index_of, base, warn_color, error_color, info_color)
	else:
		visible = _fill_tree_by_rule(root, visible_list, index_of, base, warn_color, error_color, info_color)

	var no_data := _issues.is_empty()
	if not _has_scanned:
		_empty_title.text = "Ready to validate"
		_empty_body.text = "Run a full pass to scan the project.\nEnable Auto for incremental updates after filesystem changes."
		_empty_scan.text = "Run Validation"
		_empty_scan.visible = true
		if _empty_report:
			_empty_report.visible = false
		_empty.visible = true
		_tree.visible = false
	elif visible == 0:
		if _has_active_view_filters() and not no_data:
			_empty_title.text = "No matches"
			if VFValidationSettings.is_current_scene_only():
				var scene := _edited_scene_path()
				_empty_body.text = (
					"No issues for the current scene%s.\nTurn off Scene filter to see the full project."
					% ((" (%s)" % scene.get_file()) if not scene.is_empty() else "")
				)
			else:
				_empty_body.text = "Nothing matches the current filters — or matching findings are ignored."
			_empty_scan.visible = false
			if _empty_report:
				_empty_report.visible = false
		else:
			_empty_title.text = "All clear"
			_empty_body.text = "No validation issues found."
			_empty_scan.text = "Validate again"
			_empty_scan.visible = true
			if _empty_report:
				_empty_report.visible = _html_report_exists()
		_empty.visible = true
		_tree.visible = false
	else:
		_empty.visible = false
		_tree.visible = true

	_update_severity_toggle_counts()
	issue_count_changed.emit(visible_list.size())
	if not _pending_select_fp.is_empty():
		var fp := _pending_select_fp
		_pending_select_fp = ""
		call_deferred("_select_fingerprint", fp)

func _has_active_view_filters() -> bool:
	if VFValidationSettings.is_current_scene_only():
		return true
	if VFValidationSettings.any_severity_hidden():
		return true
	if not VFValidationSettings.get_rule_filter().is_empty():
		return true
	if not _filter.is_empty():
		return true
	return false

func _html_report_exists() -> bool:
	var path := VFValidationSettings.get_html_report_path()
	return FileAccess.file_exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))

func _open_html_report() -> void:
	var path := VFValidationSettings.get_html_report_path()
	var abs_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(abs_path):
		_set_detail("No HTML report yet — run Validate first.", true)
		return
	OS.shell_open(abs_path)
	_set_detail("Opened report: %s" % path, false)

func _fill_tree_by_rule(
	root: TreeItem,
	visible_list: Array[VFValidationIssue],
	index_of: Dictionary,
	base: Control,
	warn_color: Color,
	error_color: Color,
	info_color: Color
) -> int:
	var order: Array[String] = []
	var buckets: Dictionary = {}
	if _registry:
		for rule in _registry.get_rules():
			order.append(rule.get_id())
			buckets[rule.get_id()] = []
	for issue in visible_list:
		var rid := issue.rule_id
		if not buckets.has(rid):
			order.append(rid)
			buckets[rid] = []
		buckets[rid].append(issue)

	var visible := 0
	for rid in order:
		var items: Array = buckets.get(rid, [])
		if items.is_empty():
			continue
		_sort_issues_by_severity(items)
		var group := _tree.create_item(root)
		var title := _registry.get_display_name(rid) if _registry else rid
		group.set_text(COL_SUBJECT, "%s (%d)" % [title, items.size()])
		group.set_text(COL_DETAIL, "")
		group.set_text(COL_SEVERITY, "")
		group.set_text(COL_ACTIONS, "")
		group.set_icon(COL_SUBJECT, base.get_theme_icon("Script", "EditorIcons"))
		group.set_metadata(COL_SUBJECT, {"kind": "rule", "rule_id": rid})
		group.set_selectable(COL_SUBJECT, true)
		group.set_selectable(COL_DETAIL, false)
		group.set_selectable(COL_SEVERITY, false)
		group.set_selectable(COL_ACTIONS, false)
		for issue in items:
			visible += _add_issue_row(group, issue, index_of, base, warn_color, error_color, info_color, false)
	return visible

func _fill_tree_by_missing(
	root: TreeItem,
	visible_list: Array[VFValidationIssue],
	index_of: Dictionary,
	base: Control,
	warn_color: Color,
	error_color: Color,
	info_color: Color
) -> int:
	var buckets: Dictionary = {} # missing key -> Array[VFValidationIssue]
	var order: Array[String] = []
	for issue in visible_list:
		var key := issue.related_path if not issue.related_path.is_empty() else issue.message
		if not buckets.has(key):
			order.append(key)
			buckets[key] = []
		buckets[key].append(issue)
	order.sort()

	var visible := 0
	for key in order:
		var items: Array = buckets[key]
		_sort_issues_by_severity(items)
		var group := _tree.create_item(root)
		group.set_text(COL_SUBJECT, "%s (%d)" % [_display_related(key, key), items.size()])
		group.set_text(COL_DETAIL, "")
		group.set_text(COL_SEVERITY, "")
		group.set_text(COL_ACTIONS, "")
		group.set_icon(COL_SUBJECT, base.get_theme_icon("StatusWarning", "EditorIcons"))
		group.set_tooltip_text(COL_SUBJECT, key)
		group.set_metadata(COL_SUBJECT, {"kind": "missing", "related": key})
		group.set_selectable(COL_SUBJECT, true)
		group.set_selectable(COL_DETAIL, false)
		group.set_selectable(COL_SEVERITY, false)
		group.set_selectable(COL_ACTIONS, false)
		for issue in items:
			visible += _add_issue_row(group, issue, index_of, base, warn_color, error_color, info_color, true)
	return visible

func _add_issue_row(
	parent: TreeItem,
	issue: VFValidationIssue,
	index_of: Dictionary,
	base: Control,
	_warn_color: Color,
	_error_color: Color,
	_info_color: Color,
	under_missing_group: bool
) -> int:
	var item := _tree.create_item(parent)
	var res_path := issue.resource_path
	var related := issue.related_path
	var sev_name := VFReportWriter.severity_name(issue.severity)
	var sev_icon_name := "StatusWarning"
	match int(issue.severity):
		VFValidationIssue.Severity.ERROR:
			sev_icon_name = "StatusError"
		VFValidationIssue.Severity.INFO:
			sev_icon_name = "NodeInfo"
		_:
			sev_icon_name = "StatusWarning"
	if under_missing_group:
		item.set_text(COL_SUBJECT, res_path.get_file() if not res_path.is_empty() else issue.message)
		item.set_text(COL_DETAIL, res_path)
		item.set_icon(COL_SUBJECT, _icon_for_path(res_path, base))
	else:
		item.set_text(COL_SUBJECT, res_path.get_file() if not res_path.is_empty() else issue.message)
		item.set_text(COL_DETAIL, _detail_for_issue(issue))
		item.set_icon(COL_SUBJECT, _icon_for_path(res_path, base))
	# Icon-only severity — full name in tooltip (double-click row to Open).
	item.set_text(COL_SEVERITY, "")
	item.set_icon(COL_SEVERITY, base.get_theme_icon(sev_icon_name, "EditorIcons"))
	item.set_tooltip_text(COL_SEVERITY, sev_name.capitalize())
	var idx: int = int(index_of.get(VFValidationSettings.issue_fingerprint(issue), -1))
	item.set_metadata(COL_SUBJECT, idx)
	item.set_tooltip_text(COL_SUBJECT, res_path if not res_path.is_empty() else issue.message)
	var tip1 := "[%s] %s" % [sev_name, issue.message]
	if not related.is_empty():
		tip1 = "%s\n%s" % [tip1, related]
	item.set_tooltip_text(COL_DETAIL, tip1)
	item.add_button(COL_ACTIONS, base.get_theme_icon("Folder", "EditorIcons"), BTN_REVEAL, false, "Reveal in FileSystem")
	var copy_icon := "ActionCopy"
	if not base.has_theme_icon(copy_icon, "EditorIcons"):
		copy_icon = "Duplicate"
	item.add_button(
		COL_ACTIONS,
		base.get_theme_icon(copy_icon, "EditorIcons"),
		BTN_COPY,
		false,
		"Copy related / missing path"
	)
	return 1

func _sort_issues_by_severity(items: Array) -> void:
	items.sort_custom(func(a: VFValidationIssue, b: VFValidationIssue) -> bool:
		var ra := _severity_rank(int(a.severity))
		var rb := _severity_rank(int(b.severity))
		if ra != rb:
			return ra < rb
		return a.resource_path < b.resource_path
	)

func _severity_rank(severity: int) -> int:
	match severity:
		VFValidationIssue.Severity.ERROR:
			return 0
		VFValidationIssue.Severity.WARNING:
			return 1
		_:
			return 2

## res:// paths → show basename; node paths / other → show warning message.
func _detail_for_issue(issue: VFValidationIssue) -> String:
	var related := issue.related_path
	if (
		related.begins_with("res://")
		or related.begins_with("user://")
		or related.begins_with("uid://")
	):
		return _display_related(related, issue.message)
	if not issue.message.is_empty():
		return issue.message
	return related if not related.is_empty() else ""

func _display_related(related: String, fallback: String) -> String:
	if related.is_empty():
		return fallback
	if related.begins_with("uid://"):
		return related
	var file := related.get_file()
	return file if not file.is_empty() else related

func _icon_for_path(path: String, base: Control) -> Texture2D:
	var ext := path.get_extension().to_lower()
	match ext:
		"tscn", "scn":
			return base.get_theme_icon("PackedScene", "EditorIcons")
		"tres", "res":
			return base.get_theme_icon("ResourcePreloader", "EditorIcons")
		_:
			return base.get_theme_icon("Object", "EditorIcons")

func _passes_filter(issue: VFValidationIssue) -> bool:
	if _filter.is_empty():
		return true
	var blob := "%s %s %s %s" % [issue.rule_id, issue.resource_path, issue.related_path, issue.message]
	return _filter in blob.to_lower()

func _selected_meta() -> Variant:
	var item := _tree.get_selected()
	if item == null:
		return null
	return item.get_metadata(COL_SUBJECT)

func _selected_index() -> int:
	var meta: Variant = _selected_meta()
	if typeof(meta) == TYPE_INT:
		return int(meta)
	return -1

func _selected_group() -> Dictionary:
	var meta: Variant = _selected_meta()
	if typeof(meta) == TYPE_DICTIONARY:
		return meta
	return {}

func _on_item_selected() -> void:
	var idx := _selected_index()
	if idx >= 0 and idx < _issues.size():
		var issue := _issues[idx]
		var sev := VFReportWriter.severity_name(issue.severity)
		var head := "[%s] %s" % [sev, issue.message]
		if not issue.related_path.is_empty():
			head = "%s → %s" % [head, issue.related_path.get_file() if issue.related_path.get_file() else issue.related_path]
		_set_detail(head, int(issue.severity) != VFValidationIssue.Severity.INFO)
		var tip_parts: PackedStringArray = [issue.message]
		if not issue.resource_path.is_empty():
			tip_parts.append(issue.resource_path)
		if not issue.related_path.is_empty():
			tip_parts.append("→ %s" % issue.related_path)
		if _detail:
			_detail.tooltip_text = "\n".join(tip_parts)
		return
	var group := _selected_group()
	if not group.is_empty():
		match str(group.get("kind", "")):
			"rule":
				var rid := str(group.get("rule_id", ""))
				var title := _registry.get_display_name(rid) if _registry else rid
				_set_detail("Group: %s — right-click for Ignore / Copy all" % title, false)
			"missing":
				_set_detail("Missing: %s — right-click for Ignore / Copy" % str(group.get("related", "")), true)
		if _detail:
			_detail.tooltip_text = _detail.text
		return
	if _detail:
		_detail.tooltip_text = ""

func _on_tree_gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key := event as InputEventKey
	if key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER:
		if _selected_index() >= 0:
			_open_selected()
			_tree.accept_event()
	elif key.keycode == KEY_C and key.ctrl_pressed:
		if _selected_index() >= 0:
			_copy_related_path()
			_tree.accept_event()
		elif not _selected_group().is_empty():
			_copy_group_paths()
			_tree.accept_event()

func _on_tree_button_clicked(item: TreeItem, _column: int, id: int, mouse_button: int) -> void:
	if mouse_button != MOUSE_BUTTON_LEFT or item == null:
		return
	var meta = item.get_metadata(COL_SUBJECT)
	if typeof(meta) != TYPE_INT:
		return
	var idx := int(meta)
	if idx < 0 or idx >= _issues.size():
		return
	item.select(COL_SUBJECT)
	_on_item_selected()
	match id:
		BTN_REVEAL:
			_reveal_selected()
		BTN_COPY:
			_copy_related_path()

func _on_item_mouse_selected(pos: Vector2, button: int) -> void:
	if button != MOUSE_BUTTON_RIGHT:
		return
	_context.clear()
	_context_group = {}
	var idx := _selected_index()
	var group := _selected_group()
	if idx >= 0:
		var issue := _issues[idx]
		_context.add_icon_item(_theme_icon("Load"), "Open resource", 0)
		_context.add_icon_item(_theme_icon("Folder"), "Show in FileSystem", 1)
		_context.add_separator()
		_context.add_icon_item(_theme_icon("ActionCopy"), "Copy related path", 2)
		_context.add_icon_item(_theme_icon("ActionCopy"), "Copy resource path", 3)
		_context.add_icon_item(_theme_icon("ActionCopy"), "Copy both", 4)
		_context.add_separator()
		_context.add_icon_item(_theme_icon("Remove"), "Ignore this issue", 6)
		_context.add_icon_item(_theme_icon("Remove"), "Ignore resource path", 7)
		if not issue.related_path.is_empty():
			_context.add_icon_item(_theme_icon("Remove"), "Ignore missing path", 8)
			_context.add_icon_item(_theme_icon("Remove"), "Ignore all with same related", 12)
		_context.add_icon_item(_theme_icon("Remove"), "Ignore all from this rule", 13)
		_context.add_separator()
	elif not group.is_empty():
		_context_group = group
		match str(group.get("kind", "")):
			"rule":
				_context.add_icon_item(_theme_icon("ActionCopy"), "Copy all related paths", 20)
				_context.add_icon_item(_theme_icon("Remove"), "Ignore all from this rule", 21)
			"missing":
				_context.add_icon_item(_theme_icon("ActionCopy"), "Copy missing path", 22)
				_context.add_icon_item(_theme_icon("Remove"), "Ignore all with this missing", 23)
		_context.add_separator()
	_context.add_icon_item(_theme_icon("Play"), "Full validate", 5)
	_context.add_icon_item(_theme_icon("FileList"), "Open HTML report", 14)
	_context.add_icon_item(_theme_icon("Reload"), "Clear all ignores", 9)
	# PopupMenu is a Window — needs screen coords, not Tree-local / canvas-global.
	_context.reset_size()
	var screen_pos := Vector2i(_tree.get_screen_transform() * pos)
	_context.popup(Rect2i(screen_pos, Vector2i()))

func _on_context_id(id: int) -> void:
	match id:
		0:
			_open_selected()
		1:
			_reveal_selected()
		2:
			_copy_related_path()
		3:
			_copy_resource_path()
		4:
			_copy_both_paths()
		5:
			scan_now(true, true)
		6:
			_ignore_selected_issue()
		7:
			_ignore_selected_resource_path()
		8:
			_ignore_selected_missing_path()
		9:
			VFValidationSettings.clear_all_ignores()
			_refresh()
			_set_detail("Cleared all ignores.", false)
		12:
			_ignore_all_same_related()
		13:
			_ignore_all_same_rule()
		14:
			_open_html_report()
		20, 22:
			_copy_group_paths()
		21:
			_ignore_group_rule()
		23:
			_ignore_group_missing()

func _copy_group_paths() -> void:
	var group := _context_group if not _context_group.is_empty() else _selected_group()
	if group.is_empty():
		return
	match str(group.get("kind", "")):
		"missing":
			var related := str(group.get("related", ""))
			if related.is_empty():
				return
			DisplayServer.clipboard_set(related)
			_set_detail("Copied: %s" % related, false)
		"rule":
			var rid := str(group.get("rule_id", ""))
			var lines: PackedStringArray = []
			var seen: Dictionary = {}
			for issue in _visible_issues():
				if issue.rule_id != rid:
					continue
				var p := issue.related_path if not issue.related_path.is_empty() else issue.resource_path
				if p.is_empty() or seen.has(p):
					continue
				seen[p] = true
				lines.append(p)
			if lines.is_empty():
				_set_detail("No paths to copy in this group.", true)
				return
			DisplayServer.clipboard_set("\n".join(lines))
			_set_detail("Copied %d path(s)." % lines.size(), false)

func _ignore_group_rule() -> void:
	var group := _context_group if not _context_group.is_empty() else _selected_group()
	var rid := str(group.get("rule_id", ""))
	if rid.is_empty():
		return
	var n := VFValidationSettings.ignore_all_for_rule(rid, _issues)
	_refresh()
	_set_detail("Ignored %d issue(s) from rule '%s'." % [n, rid], false)

func _ignore_group_missing() -> void:
	var group := _context_group if not _context_group.is_empty() else _selected_group()
	var related := str(group.get("related", ""))
	if related.is_empty():
		return
	var n := VFValidationSettings.ignore_all_with_related(related, _issues)
	_refresh()
	_set_detail("Ignored %d issue(s) with related path." % n, false)

func _ignore_selected_issue() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	VFValidationSettings.ignore_issue(_issues[idx])
	_refresh()
	_set_detail("Ignored issue.", false)

func _ignore_selected_resource_path() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	VFValidationSettings.ignore_path_prefix(_issues[idx].resource_path)
	_refresh()
	_set_detail("Ignored resource path.", false)

func _ignore_selected_missing_path() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var related := _issues[idx].related_path
	if related.is_empty():
		return
	VFValidationSettings.ignore_path_prefix(related)
	_refresh()
	_set_detail("Ignored missing path.", false)

func _ignore_all_same_related() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var related := _issues[idx].related_path
	var n := VFValidationSettings.ignore_all_with_related(related, _issues)
	_refresh()
	_set_detail("Ignored %d issue(s) with related path." % n, false)

func _ignore_all_same_rule() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var rid := _issues[idx].rule_id
	var n := VFValidationSettings.ignore_all_for_rule(rid, _issues)
	_refresh()
	_set_detail("Ignored %d issue(s) from rule '%s'." % [n, rid], false)

func _theme_icon(name: String) -> Texture2D:
	var base := EditorInterface.get_base_control()
	if base.has_theme_icon(name, "EditorIcons"):
		return base.get_theme_icon(name, "EditorIcons")
	return base.get_theme_icon("Duplicate", "EditorIcons")

func _open_selected() -> void:
	var idx := _selected_index()
	if idx < 0:
		_set_detail("Select an issue row (not a group).", true)
		return
	var issue := _issues[idx]
	if not _navigate_to_issue(issue):
		_set_detail("Could not open: %s" % issue.resource_path, true)
		return
	_set_detail("Opened %s" % issue.resource_path, false)

## Jump to the issue subject: scene (even if deps broken), script (+ optional line), or resource.
func _navigate_to_issue(issue: VFValidationIssue) -> bool:
	var path := issue.resource_path.strip_edges()
	if path.is_empty():
		return false
	var ext := path.get_extension().to_lower()
	match ext:
		"tscn", "scn":
			# Prefer open_scene — load() often fails on missing-dep demos and aborts jump.
			EditorInterface.open_scene_from_path(path)
			call_deferred("_try_select_related_node", issue.related_path)
			return true
		"gd":
			if not ResourceLoader.exists(path):
				return false
			var script: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if script is Script:
				var line := int(issue.meta.get("line", 0))
				var col := int(issue.meta.get("column", 0))
				EditorInterface.edit_script(script as Script, line, col)
				return true
			return false
		_:
			if not ResourceLoader.exists(path):
				return false
			var res: Variant = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
			if res == null:
				return false
			EditorInterface.edit_resource(res as Resource)
			return true

func _try_select_related_node(related: String) -> void:
	if related.is_empty():
		return
	if (
		related.begins_with("res://")
		or related.begins_with("user://")
		or related.begins_with("uid://")
	):
		return
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var node: Node = null
	if related == "." or related == root.name:
		node = root
	else:
		node = root.get_node_or_null(NodePath(related))
	if node == null:
		return
	var selection := EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)

func _reveal_selected() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var path := _issues[idx].resource_path
	if path.is_empty():
		return
	EditorInterface.get_file_system_dock().navigate_to_path(path)

func _summary_counts(issues: Array[VFValidationIssue]) -> String:
	var counts := VFReportWriter.count_by_severity(issues)
	var total := int(counts.get("error", 0)) + int(counts.get("warning", 0)) + int(counts.get("info", 0))
	return "%d issue(s) — error %d · warning %d · info %d" % [
		total,
		int(counts.get("error", 0)),
		int(counts.get("warning", 0)),
		int(counts.get("info", 0)),
	]

func _copy_related_path() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var related := _issues[idx].related_path
	if related.is_empty():
		related = _issues[idx].message
	DisplayServer.clipboard_set(related)
	_set_detail("Copied: %s" % related, false)

func _copy_resource_path() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var path := _issues[idx].resource_path
	DisplayServer.clipboard_set(path)
	_set_detail("Copied: %s" % path, false)

func _copy_both_paths() -> void:
	var idx := _selected_index()
	if idx < 0:
		return
	var issue := _issues[idx]
	DisplayServer.clipboard_set("%s\n%s" % [issue.resource_path, issue.related_path])
	_set_detail("Copied resource + related paths", false)

func _set_detail(text: String, is_warn: bool) -> void:
	if _detail == null:
		return
	_detail.text = text
	if is_warn:
		var base := EditorInterface.get_base_control()
		var warn_color := Color(1, 0.75, 0.35)
		if base.has_theme_color("warning_color", "Editor"):
			warn_color = base.get_theme_color("warning_color", "Editor")
		_detail.add_theme_color_override("font_color", warn_color)
	else:
		_detail.remove_theme_color_override("font_color")
