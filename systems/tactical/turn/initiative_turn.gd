extends TurnManager
class_name InitiativeTurn
# Alternativa plugável: ordena por stat_id configurável (default "movement" como iniciativa).
# Trocar para "speed", "agilidade" é só mudar init_stat_id.

@export var init_stat_id: String = "movement"

var _order: Array[Unit] = []
var _idx: int = 0

func _next_turn() -> void:
	if board == null:
		return
	if check_victory() != -1:
		return
	if _order.is_empty() or _idx >= _order.size():
		_build_order()
		_idx = 0
		current_round += 1
		round_started.emit(current_round)
	_current_unit = _order[_idx]
	_idx += 1
	# pula derrotados
	if _current_unit.is_defeated():
		_next_turn()
		return
	turn_started.emit(_current_unit)
	EventBus.turn_changed.emit(_current_unit)

func _build_order() -> void:
	_order = board.get_all_alive()
	_order.sort_custom(func(a: Unit, b: Unit) -> bool:
		return a.get_stat(init_stat_id) > b.get_stat(init_stat_id)
	)
