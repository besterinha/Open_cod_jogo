class_name PerformanceTestHelper
extends RefCounted

enum Metric {
	FPS,
	DRAW_CALLS,
	NODES,
	PHYSICS_2D_OBJECTS,
	MEMORY_STATIC,
}

const DEFAULT_FRAMES: int = 120

var _baseline: Dictionary = {}


func capture() -> Dictionary:
	return {
		Metric.FPS: Performance.get_monitor(Performance.TIME_FPS),
		Metric.DRAW_CALLS: Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Metric.NODES: Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		Metric.PHYSICS_2D_OBJECTS: Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		Metric.MEMORY_STATIC: Performance.get_monitor(Performance.MEMORY_STATIC),
	}


func capture_baseline() -> void:
	_baseline = capture()


func assert_below(budget: Dictionary) -> void:
	var current := capture()
	var resolved: Dictionary = _resolve_budget(budget)
	for metric in resolved:
		if current.has(metric) and current[metric] > resolved[metric]:
			push_error(
				"Performance budget exceeded for %s: %.1f > %.1f"
				% [metric, current[metric], resolved[metric]]
			)


static func make_budget(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in data:
		if key is String:
			var enum_val: Variant = Metric.get(key.to_upper(), null)
			if enum_val != null:
				result[enum_val] = data[key]
			else:
				push_error("PerformanceTestHelper: unknown metric '%s'" % key)
		else:
			result[key] = data[key]
	return result


func _resolve_budget(budget: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in budget:
		var resolved_key: Variant = key
		if key is String:
			var enum_val: Variant = Metric.get(key.to_upper(), null)
			if enum_val != null:
				resolved_key = enum_val
		result[resolved_key] = budget[key]
	return result


func assert_regression(threshold: float = 0.2) -> void:
	if _baseline.is_empty():
		push_error("Baseline not captured. Call capture_baseline() first.")
		return
	var current := capture()
	for key in _baseline:
		var baseline_val: float = _baseline.get(key, 0.0)
		var current_val: float = current.get(key, 0.0)
		var diff: float = abs(current_val - baseline_val) / max(baseline_val, 1.0)
		if diff > threshold:
			push_error(
				"Performance regression for %s: %.1f -> %.1f (%.1f%% change)"
				% [key, baseline_val, current_val, diff * 100.0]
			)


func metric_name(metric: Metric) -> String:
	match metric:
		Metric.FPS:
			return "FPS"
		Metric.DRAW_CALLS:
			return "Draw Calls"
		Metric.NODES:
			return "Nodes"
		Metric.PHYSICS_2D_OBJECTS:
			return "Physics 2D Objects"
		Metric.MEMORY_STATIC:
			return "Static Memory (MB)"
		_:
			return "Unknown"
