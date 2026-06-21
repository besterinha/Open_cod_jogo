class_name ContractTestHelper
extends RefCounted

const SIGNAL_TIMEOUT_MS: int = 2000


func assert_signal_emitted(
	sender: Object,
	signal_name: StringName,
	expected_params: Array = [],
	timeout_ms: int = SIGNAL_TIMEOUT_MS
) -> void:
	var fired := false
	var signal_args: Array = []
	var callable := func(args...):
		fired = true
		signal_args = args
	sender.connect(signal_name, callable, CONNECT_ONE_SHOT)
	await Engine.get_main_loop().create_timer(timeout_ms / 1000.0).timeout
	if not fired:
		push_error(
			"Signal %s was NOT emitted within %d ms"
			% [signal_name, timeout_ms]
		)
		return
	if expected_params.size() > 0:
		if signal_args.size() != expected_params.size():
			push_error(
				"Signal %s param count mismatch: expected %d, got %d"
				% [signal_name, expected_params.size(), signal_args.size()]
			)
			return
		for i in range(expected_params.size()):
			if signal_args[i] != expected_params[i]:
				push_error(
					"Signal %s param[%d]: expected %s, got %s"
					% [signal_name, i, str(expected_params[i]), str(signal_args[i])]
				)
				return


func assert_signal_not_emitted(
	sender: Object,
	signal_name: StringName,
	timeout_ms: int = SIGNAL_TIMEOUT_MS
) -> void:
	var fired := false
	var callable := func():
		fired = true
	sender.connect(signal_name, callable, CONNECT_ONE_SHOT)
	await Engine.get_main_loop().create_timer(timeout_ms / 1000.0).timeout
	if fired:
		push_error("Signal %s WAS emitted but should NOT have been" % signal_name)


func assert_query_response_type(
	query: Callable,
	expected_type: Variant.Type
) -> void:
	var result: Variant = query.call()
	var result_type: Variant.Type = typeof(result)
	if result_type != expected_type:
		push_error(
			"Query response type mismatch: expected %s, got %s"
			% [type_string(expected_type), type_string(result_type)]
		)


func assert_query_response_keys(
	query: Callable,
	expected_keys: Array[String]
) -> void:
	var result: Variant = query.call()
	if typeof(result) != TYPE_DICTIONARY:
		push_error("Query response is not a Dictionary (got %s)" % typeof(result))
		return
	var dict: Dictionary = result as Dictionary
	for key in expected_keys:
		if not dict.has(key):
			push_error("Query response missing expected key: %s" % key)


func type_string(type_id: Variant.Type) -> String:
	match type_id:
		TYPE_NIL:
			return "null"
		TYPE_BOOL:
			return "bool"
		TYPE_INT:
			return "int"
		TYPE_FLOAT:
			return "float"
		TYPE_STRING:
			return "String"
		TYPE_VECTOR2:
			return "Vector2"
		TYPE_VECTOR2I:
			return "Vector2i"
		TYPE_DICTIONARY:
			return "Dictionary"
		TYPE_ARRAY:
			return "Array"
		TYPE_OBJECT:
			return "Object"
		_:
			return "unknown(%d)" % type_id
