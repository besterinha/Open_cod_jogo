@tool
class_name VFValidatorRule
extends RefCounted

## Base contract for Validation Flow rules (E1). Override in subclasses.

var enabled: bool = true
## -1 = leave each issue's severity; otherwise force after the rule runs.
var severity_override: int = -1

func get_id() -> String:
	return ""

func get_display_name() -> String:
	return get_id()

func get_description() -> String:
	return ""

func supports_incremental() -> bool:
	return false

## Full project pass. `report_progress` Callable(float 0..100). `should_abort` Callable() -> bool.
func run_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	return []

## Optional: update findings from FS deltas. Default falls back to full run.
func run_incremental_async(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	return run_async(host, report_progress, should_abort)
