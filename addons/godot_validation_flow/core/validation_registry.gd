@tool
class_name VFValidationRegistry
extends RefCounted

## Registers built-in (and later custom) ValidatorRule instances.

var _rules: Array[VFValidatorRule] = []
var _by_id: Dictionary = {}

func clear() -> void:
	_rules.clear()
	_by_id.clear()

func register(rule: VFValidatorRule) -> void:
	if rule == null:
		return
	var id := rule.get_id()
	if id.is_empty():
		push_warning("Validation Flow: rule missing id")
		return
	if _by_id.has(id):
		push_warning("Validation Flow: duplicate rule id '%s'" % id)
		return
	_rules.append(rule)
	_by_id[id] = rule

func get_rules() -> Array[VFValidatorRule]:
	return _rules.duplicate()

func get_rule(id: String) -> VFValidatorRule:
	return _by_id.get(id) as VFValidatorRule

func get_display_name(rule_id: String) -> String:
	var rule := get_rule(rule_id)
	if rule:
		return rule.get_display_name()
	return rule_id
