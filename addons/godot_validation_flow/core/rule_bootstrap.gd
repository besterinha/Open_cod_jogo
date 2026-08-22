@tool
class_name VFRuleBootstrap
extends RefCounted

## Built-ins from VFProjectValidationConfig / ProjectSettings.
## Advanced script definitions only via explicit advanced paths.

const MissingDepsRule := preload("res://addons/godot_validation_flow/rules/missing_dependencies_rule.gd")
const BrokenUidRule := preload("res://addons/godot_validation_flow/rules/broken_uid_rule.gd")
const ExportIntegrityRule := preload("res://addons/godot_validation_flow/rules/export_integrity_rule.gd")
const ExportCoverageRule := preload("res://addons/godot_validation_flow/rules/export_coverage_rule.gd")
const DuplicateUidRule := preload("res://addons/godot_validation_flow/rules/duplicate_uid_rule.gd")
const DuplicateBasenameRule := preload("res://addons/godot_validation_flow/rules/duplicate_basename_rule.gd")
const OrphanAssetsRule := preload("res://addons/godot_validation_flow/rules/orphan_assets_rule.gd")
const AutoloadPathsRule := preload("res://addons/godot_validation_flow/rules/autoload_paths_rule.gd")
const EmptyNodePathsRule := preload("res://addons/godot_validation_flow/rules/empty_node_paths_rule.gd")
const UidMismatchRule := preload("res://addons/godot_validation_flow/rules/uid_mismatch_rule.gd")
const ConfigWarningsRule := preload("res://addons/godot_validation_flow/rules/configuration_warnings_rule.gd")
const FilenameSubstringRule := preload("res://addons/godot_validation_flow/rules/filename_substring_rule.gd")
const ScriptHooksRule := preload("res://addons/godot_validation_flow/rules/script_hooks_rule.gd")
const AdvancedDefScript := preload("res://addons/godot_validation_flow/core/rule_definition.gd")

static func build_registry() -> VFValidationRegistry:
	var registry := VFValidationRegistry.new()
	populate_registry(registry)
	return registry

## Clear and re-register into an existing registry (hot reload; keeps dock/runner refs).
static func populate_registry(registry: VFValidationRegistry) -> void:
	if registry == null:
		return
	VFValidationSettings.ensure_project_settings()
	registry.clear()
	if VFValidationSettings.is_builtin_rule_enabled(MissingDepsRule.RULE_ID):
		registry.register(MissingDepsRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(BrokenUidRule.RULE_ID):
		registry.register(BrokenUidRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(DuplicateUidRule.RULE_ID):
		registry.register(DuplicateUidRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(UidMismatchRule.RULE_ID):
		registry.register(UidMismatchRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(ExportIntegrityRule.RULE_ID):
		registry.register(ExportIntegrityRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(ExportCoverageRule.RULE_ID):
		registry.register(ExportCoverageRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(OrphanAssetsRule.RULE_ID):
		registry.register(OrphanAssetsRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(DuplicateBasenameRule.RULE_ID):
		registry.register(DuplicateBasenameRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(AutoloadPathsRule.RULE_ID):
		registry.register(AutoloadPathsRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(EmptyNodePathsRule.RULE_ID):
		registry.register(EmptyNodePathsRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(ConfigWarningsRule.RULE_ID):
		registry.register(ConfigWarningsRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(FilenameSubstringRule.RULE_ID):
		registry.register(FilenameSubstringRule.new())
	if VFValidationSettings.is_builtin_rule_enabled(ScriptHooksRule.RULE_ID):
		registry.register(ScriptHooksRule.new())
	_register_advanced_definitions(registry)

static func _register_advanced_definitions(registry: VFValidationRegistry) -> void:
	var seen: Dictionary = {}
	for path in VFValidationSettings.get_advanced_custom_rule_definition_paths():
		var p := str(path).strip_edges()
		if p.is_empty() or seen.has(p):
			continue
		seen[p] = true
		_try_register_definition(registry, p)

static func _try_register_definition(registry: VFValidationRegistry, path: String) -> void:
	if not ResourceLoader.exists(path):
		push_warning("Validation Flow: advanced rule definition missing: %s" % path)
		return
	var res: Resource = load(path) as Resource
	if res == null:
		push_warning("Validation Flow: could not load advanced rule definition %s" % path)
		return
	if res.get_script() != AdvancedDefScript:
		push_warning(
			"Validation Flow: %s is not an advanced rule definition resource" % path
		)
		return
	if not bool(res.get("enabled")):
		return
	if not res.has_method("instantiate_rule"):
		return
	var rule: VFValidatorRule = res.call("instantiate_rule")
	if rule == null:
		return
	registry.register(rule)
