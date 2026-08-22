@tool
class_name VFValidationRunner
extends RefCounted

## Runs enabled rules (full or incremental) and aggregates issues.
## Scan bodies are synchronous so Play/Export gates can block without coroutines.

var registry: VFValidationRegistry

func _init(p_registry: VFValidationRegistry = null) -> void:
	registry = p_registry

func run_all(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	return _run(host, report_progress, should_abort, false)

func run_incremental(
	host: Node,
	report_progress: Callable,
	should_abort: Callable
) -> Array[VFValidationIssue]:
	return _run(host, report_progress, should_abort, true)

func _run(
	host: Node,
	report_progress: Callable,
	should_abort: Callable,
	incremental: bool
) -> Array[VFValidationIssue]:
	var out: Array[VFValidationIssue] = []
	if registry == null:
		return out
	var enabled: Array[VFValidatorRule] = []
	for r in registry.get_rules():
		if r.enabled:
			enabled.append(r)
	var n := enabled.size()
	if n == 0:
		return out
	var i := 0
	for rule in enabled:
		if should_abort.call():
			return out
		var rule_progress := func(p: float) -> void:
			var base := 100.0 * float(i) / float(n)
			var span := 100.0 / float(n)
			report_progress.call(base + span * clampf(p, 0.0, 100.0) / 100.0)
		var found: Array[VFValidationIssue]
		if incremental and rule.supports_incremental():
			found = rule.run_incremental_async(host, rule_progress, should_abort)
		else:
			found = rule.run_async(host, rule_progress, should_abort)
		for issue in found:
			if rule.severity_override >= 0:
				issue.severity = rule.severity_override
			out.append(issue)
		i += 1
	report_progress.call(100.0)
	return out
