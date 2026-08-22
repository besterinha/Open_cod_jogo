@tool
class_name VFValidationSettings
extends RefCounted

## Persist Validation Flow prefs under the editor project settings dir (not addons/).
## Built-in rule toggles + extra definition paths live in ProjectSettings (team-shared).

const FILE_NAME := "godot_validation_flow.cfg"
const SECTION := "validation_flow"
const KEY_AUTO_SCAN := "auto_scan_enabled"
const KEY_GROUP_MODE := "group_mode"
const KEY_IGNORED_ISSUES := "ignored_issues"
const KEY_IGNORED_PATHS := "ignored_path_prefixes"
const KEY_PROFILE_OVERRIDE := "profile_override_path"
const KEY_SEVERITY_FILTER := "severity_filter" # legacy 0/1/2 — migrated to toggles
const KEY_SHOW_ERROR := "show_severity_error"
const KEY_SHOW_WARNING := "show_severity_warning"
const KEY_SHOW_INFO := "show_severity_info"
const KEY_RULE_FILTER := "rule_filter"
const KEY_CURRENT_SCENE_ONLY := "current_scene_only"

const GROUP_BY_RULE := "rule"
const GROUP_BY_MISSING := "missing"
const PROFILES_DIR := "res://validators/profiles"
const DEFAULT_PROFILE_PATH := "res://validators/profiles/full_project.tres"

const PS_MISSING_DEPS := "godot_validation_flow/rules/missing_dependencies"
const PS_BROKEN_UID := "godot_validation_flow/rules/broken_uid"
const PS_DUPLICATE_UID := "godot_validation_flow/rules/duplicate_uid"
const PS_UID_MISMATCH := "godot_validation_flow/rules/uid_mismatch"
const PS_EXPORT_INTEGRITY := "godot_validation_flow/rules/export_integrity"
const PS_EXPORT_COVERAGE := "godot_validation_flow/rules/export_coverage"
const PS_ORPHAN_ASSETS := "godot_validation_flow/rules/orphan_assets"
const PS_DUPLICATE_BASENAME := "godot_validation_flow/rules/duplicate_basename"
const PS_AUTOLOAD_PATHS := "godot_validation_flow/rules/autoload_paths"
const PS_EMPTY_NODE_PATHS := "godot_validation_flow/rules/empty_node_paths"
const PS_CONFIG_WARNINGS := "godot_validation_flow/rules/configuration_warnings"
const PS_SCRIPT_HOOKS := "godot_validation_flow/rules/script_hooks"
const PS_SCRIPT_HOOKS_SEVERITY := "godot_validation_flow/rules/script_hooks_severity"
const PS_CSHARP_ATTRIBUTES := "godot_validation_flow/rules/csharp_attributes"
const PS_FILENAME := "godot_validation_flow/rules/filename_substring"
const PS_FILENAME_NEEDLE := "godot_validation_flow/rules/filename_substring_text"
const PS_FILENAME_EXTS := "godot_validation_flow/rules/filename_substring_extensions"
const PS_FILENAME_SEVERITY := "godot_validation_flow/rules/filename_substring_severity"
## Path to data-only VFProjectValidationConfig (.tres). Empty = use default path if present.
const PS_CONFIG_PATH := "godot_validation_flow/config_path"
## Advanced last-gate only: paths to script-backed definition `.tres`.
const PS_ADVANCED_DEFINITIONS := "godot_validation_flow/advanced/custom_rule_definitions"

const DEFAULT_CONFIG_PATH := "res://validators/ProjectValidationRules.tres"

static func ensure_project_settings() -> void:
	_ensure_setting(PS_MISSING_DEPS, true, TYPE_BOOL)
	_ensure_setting(PS_BROKEN_UID, true, TYPE_BOOL)
	_ensure_setting(PS_DUPLICATE_UID, true, TYPE_BOOL)
	_ensure_setting(PS_UID_MISMATCH, true, TYPE_BOOL)
	_ensure_setting(PS_EXPORT_INTEGRITY, true, TYPE_BOOL)
	_ensure_setting(PS_EXPORT_COVERAGE, true, TYPE_BOOL)
	_ensure_setting(PS_ORPHAN_ASSETS, true, TYPE_BOOL)
	_ensure_setting(PS_DUPLICATE_BASENAME, true, TYPE_BOOL)
	_ensure_setting(PS_AUTOLOAD_PATHS, true, TYPE_BOOL)
	_ensure_setting(PS_EMPTY_NODE_PATHS, true, TYPE_BOOL)
	_ensure_setting(PS_CONFIG_WARNINGS, true, TYPE_BOOL)
	_ensure_setting(PS_SCRIPT_HOOKS, true, TYPE_BOOL)
	_ensure_setting(PS_SCRIPT_HOOKS_SEVERITY, 1, TYPE_INT)
	_ensure_setting(PS_CSHARP_ATTRIBUTES, true, TYPE_BOOL)
	_ensure_setting(PS_FILENAME, true, TYPE_BOOL)
	_ensure_setting(PS_FILENAME_NEEDLE, "broken_", TYPE_STRING)
	_ensure_setting(
		PS_FILENAME_EXTS,
		PackedStringArray(["tscn"]),
		TYPE_PACKED_STRING_ARRAY
	)
	_ensure_setting(PS_FILENAME_SEVERITY, 0, TYPE_INT)
	_ensure_setting(PS_CONFIG_PATH, DEFAULT_CONFIG_PATH, TYPE_STRING)
	_ensure_setting(PS_ADVANCED_DEFINITIONS, PackedStringArray(), TYPE_PACKED_STRING_ARRAY)
	ProjectSettings.add_property_info({
		"name": PS_FILENAME_SEVERITY,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Info,Warning,Error",
	})
	ProjectSettings.add_property_info({
		"name": PS_SCRIPT_HOOKS_SEVERITY,
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Info,Warning,Error",
	})
	ProjectSettings.add_property_info({
		"name": PS_CONFIG_PATH,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres,*.res",
	})
	if ProjectSettings.has_method("set_as_basic"):
		ProjectSettings.set_as_basic(PS_CONFIG_PATH, true)
		ProjectSettings.set_as_basic(PS_MISSING_DEPS, true)
		ProjectSettings.set_as_basic(PS_BROKEN_UID, true)
		ProjectSettings.set_as_basic(PS_DUPLICATE_UID, true)
		ProjectSettings.set_as_basic(PS_UID_MISMATCH, true)
		ProjectSettings.set_as_basic(PS_EXPORT_INTEGRITY, true)
		ProjectSettings.set_as_basic(PS_EXPORT_COVERAGE, true)
		ProjectSettings.set_as_basic(PS_ORPHAN_ASSETS, true)
		ProjectSettings.set_as_basic(PS_DUPLICATE_BASENAME, true)
		ProjectSettings.set_as_basic(PS_AUTOLOAD_PATHS, true)
		ProjectSettings.set_as_basic(PS_EMPTY_NODE_PATHS, true)
		ProjectSettings.set_as_basic(PS_CONFIG_WARNINGS, true)
		ProjectSettings.set_as_basic(PS_SCRIPT_HOOKS, true)
		ProjectSettings.set_as_basic(PS_CSHARP_ATTRIBUTES, true)
		ProjectSettings.set_as_basic(PS_FILENAME, true)
		ProjectSettings.set_as_basic(PS_FILENAME_NEEDLE, true)
		ProjectSettings.set_as_basic(PS_ADVANCED_DEFINITIONS, false)

static func _ensure_setting(key: String, default: Variant, type: int) -> void:
	if not ProjectSettings.has_setting(key):
		ProjectSettings.set_setting(key, default)
	ProjectSettings.add_property_info({
		"name": key,
		"type": type,
	})
	ProjectSettings.set_initial_value(key, default)

## Data-only project policy from config .tres (no scripts).
static func get_project_config() -> VFProjectValidationConfig:
	var path := str(ProjectSettings.get_setting(PS_CONFIG_PATH, DEFAULT_CONFIG_PATH)).strip_edges()
	if path.is_empty():
		path = DEFAULT_CONFIG_PATH
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path) as Resource
	if loaded is VFProjectValidationConfig:
		return loaded as VFProjectValidationConfig
	return null

## Active scan profile: session override → project config → default resource → in-memory default.
static func get_active_profile() -> VFValidationProfile:
	var override_path := str(_load().get_value(SECTION, KEY_PROFILE_OVERRIDE, "")).strip_edges()
	if not override_path.is_empty() and ResourceLoader.exists(override_path):
		var ov: Resource = load(override_path) as Resource
		if ov is VFValidationProfile:
			return ov as VFValidationProfile
	var cfg := get_project_config()
	if cfg != null and cfg.active_profile != null:
		return cfg.active_profile
	if ResourceLoader.exists(DEFAULT_PROFILE_PATH):
		var def: Resource = load(DEFAULT_PROFILE_PATH) as Resource
		if def is VFValidationProfile:
			return def as VFValidationProfile
	return VFValidationProfile.make_default()

static func get_profile_override_path() -> String:
	return str(_load().get_value(SECTION, KEY_PROFILE_OVERRIDE, "")).strip_edges()

static func set_profile_override_path(path: String) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_PROFILE_OVERRIDE, path.strip_edges())
	_save(cfg)

static func list_profile_paths() -> PackedStringArray:
	var out: PackedStringArray = []
	var dir := DirAccess.open(PROFILES_DIR)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not dir.current_is_dir() and name.get_extension().to_lower() in ["tres", "res"]:
			out.append(PROFILES_DIR.path_join(name))
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

## Legacy 0=All, 1=Warning+, 2=Error only (kept for migration).
static func get_severity_filter() -> int:
	return int(_load().get_value(SECTION, KEY_SEVERITY_FILTER, 0))

static func set_severity_filter(level: int) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_SEVERITY_FILTER, clampi(level, 0, 2))
	# Sync toggle keys from legacy ladder.
	match clampi(level, 0, 2):
		1:
			cfg.set_value(SECTION, KEY_SHOW_ERROR, true)
			cfg.set_value(SECTION, KEY_SHOW_WARNING, true)
			cfg.set_value(SECTION, KEY_SHOW_INFO, false)
		2:
			cfg.set_value(SECTION, KEY_SHOW_ERROR, true)
			cfg.set_value(SECTION, KEY_SHOW_WARNING, false)
			cfg.set_value(SECTION, KEY_SHOW_INFO, false)
		_:
			cfg.set_value(SECTION, KEY_SHOW_ERROR, true)
			cfg.set_value(SECTION, KEY_SHOW_WARNING, true)
			cfg.set_value(SECTION, KEY_SHOW_INFO, true)
	_save(cfg)

static func is_severity_shown(severity: int) -> bool:
	var cfg := _load()
	if not cfg.has_section_key(SECTION, KEY_SHOW_ERROR):
		match get_severity_filter():
			1:
				return int(severity) >= VFValidationIssue.Severity.WARNING
			2:
				return int(severity) >= VFValidationIssue.Severity.ERROR
			_:
				return true
	match int(severity):
		VFValidationIssue.Severity.ERROR:
			return bool(cfg.get_value(SECTION, KEY_SHOW_ERROR, true))
		VFValidationIssue.Severity.INFO:
			return bool(cfg.get_value(SECTION, KEY_SHOW_INFO, true))
		_:
			return bool(cfg.get_value(SECTION, KEY_SHOW_WARNING, true))

static func set_severity_shown(severity: int, shown: bool) -> void:
	var cfg := _load()
	var key := KEY_SHOW_WARNING
	match int(severity):
		VFValidationIssue.Severity.ERROR:
			key = KEY_SHOW_ERROR
		VFValidationIssue.Severity.INFO:
			key = KEY_SHOW_INFO
		_:
			key = KEY_SHOW_WARNING
	cfg.set_value(SECTION, key, shown)
	_save(cfg)

static func any_severity_hidden() -> bool:
	return (
		not is_severity_shown(VFValidationIssue.Severity.ERROR)
		or not is_severity_shown(VFValidationIssue.Severity.WARNING)
		or not is_severity_shown(VFValidationIssue.Severity.INFO)
	)

static func get_rule_filter() -> String:
	return str(_load().get_value(SECTION, KEY_RULE_FILTER, ""))

static func set_rule_filter(rule_id: String) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_RULE_FILTER, rule_id)
	_save(cfg)

static func is_current_scene_only() -> bool:
	return bool(_load().get_value(SECTION, KEY_CURRENT_SCENE_ONLY, false))

static func set_current_scene_only(enabled: bool) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_CURRENT_SCENE_ONLY, enabled)
	_save(cfg)

static func issue_passes_severity_filter(issue: VFValidationIssue) -> bool:
	return is_severity_shown(issue.severity)

static func is_builtin_rule_enabled(rule_id: String) -> bool:
	var cfg := get_project_config()
	match rule_id:
		"missing_dependencies":
			if cfg:
				return cfg.missing_dependencies
			return bool(ProjectSettings.get_setting(PS_MISSING_DEPS, true))
		"broken_uid":
			if cfg:
				return cfg.broken_uid
			return bool(ProjectSettings.get_setting(PS_BROKEN_UID, true))
		"duplicate_uid":
			if cfg:
				return cfg.duplicate_uid
			return bool(ProjectSettings.get_setting(PS_DUPLICATE_UID, true))
		"uid_mismatch":
			if cfg:
				return cfg.uid_mismatch
			return bool(ProjectSettings.get_setting(PS_UID_MISMATCH, true))
		"export_integrity":
			if cfg:
				return cfg.export_integrity
			return bool(ProjectSettings.get_setting(PS_EXPORT_INTEGRITY, true))
		"export_coverage":
			if cfg:
				return cfg.export_coverage
			return bool(ProjectSettings.get_setting(PS_EXPORT_COVERAGE, true))
		"orphan_assets":
			if cfg:
				return cfg.orphan_assets
			return bool(ProjectSettings.get_setting(PS_ORPHAN_ASSETS, true))
		"duplicate_basename":
			if cfg:
				return cfg.duplicate_basename
			return bool(ProjectSettings.get_setting(PS_DUPLICATE_BASENAME, true))
		"autoload_paths":
			if cfg:
				return cfg.autoload_paths
			return bool(ProjectSettings.get_setting(PS_AUTOLOAD_PATHS, true))
		"empty_node_paths":
			if cfg:
				return cfg.empty_node_paths
			return bool(ProjectSettings.get_setting(PS_EMPTY_NODE_PATHS, true))
		"configuration_warnings":
			if cfg:
				return cfg.configuration_warnings
			return bool(ProjectSettings.get_setting(PS_CONFIG_WARNINGS, true))
		"script_hooks":
			if cfg:
				return cfg.script_hooks
			return bool(ProjectSettings.get_setting(PS_SCRIPT_HOOKS, true))
		"filename_substring":
			if cfg:
				if not cfg.filename_substring_enabled:
					return false
				return not cfg.filename_substring_text.strip_edges().is_empty()
			if not bool(ProjectSettings.get_setting(PS_FILENAME, true)):
				return false
			return not get_filename_substring().is_empty()
		_:
			return true

static func get_script_hooks_severity() -> int:
	var idx := 1
	var cfg := get_project_config()
	if cfg:
		idx = cfg.script_hooks_severity
	else:
		idx = int(ProjectSettings.get_setting(PS_SCRIPT_HOOKS_SEVERITY, 1))
	match clampi(idx, 0, 2):
		0:
			return VFValidationIssue.Severity.INFO
		2:
			return VFValidationIssue.Severity.ERROR
		_:
			return VFValidationIssue.Severity.WARNING

static func is_csharp_attributes_enabled() -> bool:
	var cfg := get_project_config()
	if cfg:
		return cfg.csharp_attributes
	return bool(ProjectSettings.get_setting(PS_CSHARP_ATTRIBUTES, true))

static func is_play_gate_enabled() -> bool:
	var cfg := get_project_config()
	if cfg:
		return cfg.block_play_on_issues
	return false

static func get_play_gate_severity_mode() -> int:
	var cfg := get_project_config()
	if cfg:
		return cfg.play_gate_severity
	return 1

static func is_export_gate_enabled() -> bool:
	var cfg := get_project_config()
	if cfg:
		return cfg.block_export_on_issues
	return false

static func get_export_gate_severity_mode() -> int:
	var cfg := get_project_config()
	if cfg:
		return cfg.export_gate_severity
	return 1

static func should_write_json_report() -> bool:
	var cfg := get_project_config()
	if cfg:
		return cfg.write_json_report
	return true

static func should_write_html_report() -> bool:
	var cfg := get_project_config()
	if cfg:
		return cfg.write_html_report
	return true

static func get_json_report_path() -> String:
	var cfg := get_project_config()
	if cfg and not cfg.json_report_path.strip_edges().is_empty():
		return cfg.json_report_path.strip_edges()
	return "res://.godot/validation_report.json"

static func get_html_report_path() -> String:
	var json_path := get_json_report_path()
	if json_path.get_extension().to_lower() == "json":
		return json_path.get_basename() + ".html"
	return json_path + ".html"

static func get_filename_substring() -> String:
	var cfg := get_project_config()
	if cfg:
		return cfg.filename_substring_text.strip_edges()
	return str(ProjectSettings.get_setting(PS_FILENAME_NEEDLE, "broken_")).strip_edges()

static func get_filename_extensions() -> PackedStringArray:
	var cfg := get_project_config()
	if cfg:
		return cfg.filename_substring_extensions
	var v: Variant = ProjectSettings.get_setting(
		PS_FILENAME_EXTS,
		PackedStringArray(["tscn"])
	)
	if v is PackedStringArray:
		return v
	return PackedStringArray(["tscn"])

static func get_filename_severity() -> int:
	var idx := 0
	var cfg := get_project_config()
	if cfg:
		idx = cfg.filename_substring_severity
	else:
		idx = int(ProjectSettings.get_setting(PS_FILENAME_SEVERITY, 0))
	match clampi(idx, 0, 2):
		1:
			return VFValidationIssue.Severity.WARNING
		2:
			return VFValidationIssue.Severity.ERROR
		_:
			return VFValidationIssue.Severity.INFO

static func get_advanced_custom_rule_definition_paths() -> PackedStringArray:
	var v: Variant = ProjectSettings.get_setting(PS_ADVANCED_DEFINITIONS, PackedStringArray())
	if v is PackedStringArray:
		return v
	return PackedStringArray()

## @deprecated Use get_advanced_custom_rule_definition_paths()
static func get_extra_rule_definition_paths() -> PackedStringArray:
	return get_advanced_custom_rule_definition_paths()

static func _config_path() -> String:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_paths().get_project_settings_dir().path_join(FILE_NAME)
	# CLI / headless: same folder Godot uses for project editor settings
	return ProjectSettings.globalize_path("res://.godot/editor").path_join(FILE_NAME)

static func _load() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.load(_config_path())
	return cfg

static func _save(cfg: ConfigFile) -> void:
	var path := _config_path()
	var dir_path := path.get_base_dir()
	DirAccess.make_dir_recursive_absolute(dir_path)
	cfg.save(path)

static func is_auto_scan_enabled() -> bool:
	return bool(_load().get_value(SECTION, KEY_AUTO_SCAN, false))

static func set_auto_scan_enabled(enabled: bool) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_AUTO_SCAN, enabled)
	_save(cfg)

static func get_group_mode() -> String:
	var mode := str(_load().get_value(SECTION, KEY_GROUP_MODE, GROUP_BY_RULE))
	if mode != GROUP_BY_MISSING:
		return GROUP_BY_RULE
	return GROUP_BY_MISSING

static func set_group_mode(mode: String) -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_GROUP_MODE, mode)
	_save(cfg)

static func get_ignored_issues() -> PackedStringArray:
	var v: Variant = _load().get_value(SECTION, KEY_IGNORED_ISSUES, PackedStringArray())
	if v is PackedStringArray:
		return v
	return PackedStringArray()

static func get_ignored_path_prefixes() -> PackedStringArray:
	var v: Variant = _load().get_value(SECTION, KEY_IGNORED_PATHS, PackedStringArray())
	if v is PackedStringArray:
		return v
	return PackedStringArray()

static func issue_fingerprint(issue: VFValidationIssue) -> String:
	return "%s|%s|%s" % [issue.rule_id, issue.resource_path, issue.related_path]

static func is_issue_ignored(issue: VFValidationIssue) -> bool:
	var key := issue_fingerprint(issue)
	return key in get_ignored_issues()

static func ignore_issue(issue: VFValidationIssue) -> void:
	var cfg := _load()
	var arr := get_ignored_issues()
	var key := issue_fingerprint(issue)
	if key in arr:
		return
	arr.append(key)
	cfg.set_value(SECTION, KEY_IGNORED_ISSUES, arr)
	_save(cfg)

## Ignore every issue in `candidates` that matches rule_id. Returns newly ignored count.
static func ignore_all_for_rule(rule_id: String, candidates: Array[VFValidationIssue]) -> int:
	var cfg := _load()
	var arr := get_ignored_issues()
	var n := 0
	for issue in candidates:
		if issue.rule_id != rule_id:
			continue
		var key := issue_fingerprint(issue)
		if key in arr:
			continue
		arr.append(key)
		n += 1
	if n > 0:
		cfg.set_value(SECTION, KEY_IGNORED_ISSUES, arr)
		_save(cfg)
	return n

## Ignore every issue sharing the same related_path.
static func ignore_all_with_related(related: String, candidates: Array[VFValidationIssue]) -> int:
	var target := related.strip_edges()
	if target.is_empty():
		return 0
	var cfg := _load()
	var arr := get_ignored_issues()
	var n := 0
	for issue in candidates:
		if issue.related_path != target:
			continue
		var key := issue_fingerprint(issue)
		if key in arr:
			continue
		arr.append(key)
		n += 1
	if n > 0:
		cfg.set_value(SECTION, KEY_IGNORED_ISSUES, arr)
		_save(cfg)
	return n

static func ignore_path_prefix(prefix: String) -> void:
	var p := prefix.strip_edges()
	if p.is_empty():
		return
	var cfg := _load()
	var arr := get_ignored_path_prefixes()
	if p in arr:
		return
	arr.append(p)
	cfg.set_value(SECTION, KEY_IGNORED_PATHS, arr)
	_save(cfg)

static func is_path_ignored(path: String) -> bool:
	if path.is_empty():
		return false
	for prefix in get_ignored_path_prefixes():
		if path == prefix or path.begins_with(prefix):
			return true
	return false

static func clear_all_ignores() -> void:
	var cfg := _load()
	cfg.set_value(SECTION, KEY_IGNORED_ISSUES, PackedStringArray())
	cfg.set_value(SECTION, KEY_IGNORED_PATHS, PackedStringArray())
	_save(cfg)
