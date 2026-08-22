@tool
class_name VFValidationIssue
extends RefCounted

## One finding from a ValidatorRule.

enum Severity { INFO, WARNING, ERROR }

var rule_id: String = ""
var severity: int = Severity.WARNING
var message: String = ""
## Primary subject to open / reveal (usually the referrer resource).
var resource_path: String = ""
## Optional secondary path (e.g. missing dependency).
var related_path: String = ""
var meta: Dictionary = {}

static func create(
	p_rule_id: String,
	p_message: String,
	p_resource_path: String,
	p_related_path: String = "",
	p_severity: int = Severity.WARNING
) -> VFValidationIssue:
	var issue := VFValidationIssue.new()
	issue.rule_id = p_rule_id
	issue.message = p_message
	issue.resource_path = p_resource_path
	issue.related_path = p_related_path
	issue.severity = p_severity
	return issue
