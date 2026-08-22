@tool
extends VFValidatorRule

## ADVANCED example — last-gate custom rule script.
## Do not use this for ordinary project config. Prefer Project Settings built-ins.
## To load: create a VFValidationRuleDefinition `.tres` pointing at this script,
## then add that `.tres` path under:
##   Project Settings → godot_validation_flow/advanced/custom_rule_definitions

const RULE_ID := "example_advanced_custom"

func get_id() -> String:
	return RULE_ID

func get_display_name() -> String:
	return "Example Advanced Custom"

func get_description() -> String:
	return "Advanced last-gate sample (not used unless explicitly registered)."

func run_async(
	_host: Node,
	report_progress: Callable,
	_should_abort: Callable
) -> Array[VFValidationIssue]:
	report_progress.call(100.0)
	return []
