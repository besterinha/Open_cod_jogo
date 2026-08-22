@tool
class_name VFIssueIndex
extends RefCounted

## Shared issue lookup for Inspector banner, FS tooltips, and dock.

signal changed

var _all: Array[VFValidationIssue] = []
var _by_resource: Dictionary = {} # path -> Array[VFValidationIssue]
var _by_related: Dictionary = {}
var _counts := {"info": 0, "warning": 0, "error": 0}

func set_issues(issues: Array[VFValidationIssue]) -> void:
	_all.clear()
	_by_resource.clear()
	_by_related.clear()
	_counts = {"info": 0, "warning": 0, "error": 0}
	for issue in issues:
		if VFValidationSettings.is_path_ignored(issue.resource_path):
			continue
		if VFValidationSettings.is_path_ignored(issue.related_path):
			continue
		if VFValidationSettings.is_issue_ignored(issue):
			continue
		_all.append(issue)
		_bucket(_by_resource, issue.resource_path, issue)
		if not issue.related_path.is_empty():
			_bucket(_by_related, issue.related_path, issue)
		match int(issue.severity):
			VFValidationIssue.Severity.ERROR:
				_counts["error"] = int(_counts["error"]) + 1
			VFValidationIssue.Severity.INFO:
				_counts["info"] = int(_counts["info"]) + 1
			_:
				_counts["warning"] = int(_counts["warning"]) + 1
	changed.emit()

func all_issues() -> Array[VFValidationIssue]:
	return _all

func counts() -> Dictionary:
	return _counts.duplicate()

func total() -> int:
	return _all.size()

func for_path(path: String) -> Array[VFValidationIssue]:
	var p := path.strip_edges()
	if p.is_empty():
		return []
	var out: Array[VFValidationIssue] = []
	for issue in _by_resource.get(p, []):
		out.append(issue)
	# Also surface when this path is the missing/related target.
	for issue in _by_related.get(p, []):
		if issue in out:
			continue
		out.append(issue)
	return out

## Counts for one resource path: { "error", "warning", "info", "total" }.
func counts_for_path(path: String) -> Dictionary:
	var c := {"error": 0, "warning": 0, "info": 0, "total": 0}
	for issue in for_path(path):
		c["total"] = int(c["total"]) + 1
		match int(issue.severity):
			VFValidationIssue.Severity.ERROR:
				c["error"] = int(c["error"]) + 1
			VFValidationIssue.Severity.INFO:
				c["info"] = int(c["info"]) + 1
			_:
				c["warning"] = int(c["warning"]) + 1
	return c

func for_object(obj: Object) -> Array[VFValidationIssue]:
	if obj == null:
		return []
	if obj is Resource:
		var res := obj as Resource
		if not res.resource_path.is_empty():
			return for_path(res.resource_path)
	if obj is Node:
		var node := obj as Node
		var scene := node.scene_file_path
		if scene.is_empty() and node.owner != null:
			scene = node.owner.scene_file_path
		if scene.is_empty():
			var edited := EditorInterface.get_edited_scene_root()
			if edited != null:
				scene = edited.scene_file_path
		if scene.is_empty():
			return []
		return for_path(scene)
	return []

func _bucket(map: Dictionary, key: String, issue: VFValidationIssue) -> void:
	var k := key.strip_edges()
	if k.is_empty():
		return
	if not map.has(k):
		map[k] = []
	map[k].append(issue)
