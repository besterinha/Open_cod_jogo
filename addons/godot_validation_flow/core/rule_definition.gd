@tool
extends Resource

## ADVANCED last-gate only (not listed as a friendly Create-Resource product type).
## Ordinary config = VFProjectValidationConfig / Project Settings — no scripts.
## Wire via godot_validation_flow/advanced/custom_rule_definitions paths only.

enum SeverityMode { RULE_DEFAULT, INFO, WARNING, ERROR }

@export var rule_script: Script
@export var enabled: bool = true
@export var severity_mode: SeverityMode = SeverityMode.RULE_DEFAULT

func instantiate_rule() -> VFValidatorRule:
	if rule_script == null:
		push_warning(
			"Validation Flow: advanced rule definition missing rule_script (%s)"
			% resource_path
		)
		return null
	var instance: Object = rule_script.new()
	if instance == null:
		push_warning("Validation Flow: could not instance %s" % rule_script.resource_path)
		return null
	if not (instance is VFValidatorRule):
		push_warning(
			"Validation Flow: %s must extend VFValidatorRule" % rule_script.resource_path
		)
		return null
	var rule := instance as VFValidatorRule
	if rule.get_id().is_empty():
		push_warning(
			"Validation Flow: custom rule %s missing get_id()" % rule_script.resource_path
		)
		return null
	rule.enabled = enabled
	rule.severity_override = _severity_override_value()
	return rule

func _severity_override_value() -> int:
	match severity_mode:
		SeverityMode.INFO:
			return VFValidationIssue.Severity.INFO
		SeverityMode.WARNING:
			return VFValidationIssue.Severity.WARNING
		SeverityMode.ERROR:
			return VFValidationIssue.Severity.ERROR
		_:
			return -1
