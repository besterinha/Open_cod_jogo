class_name TeamRoundRobin
extends TurnManager
# Default plugável: times alternam, cada unidade do time age uma vez por round.
# Ex: Team0: A,B -> Team1: X,Y -> round++

var _team_turn: int = 0  # 0 ou 1
var _unit_idx: int = 0
var _team_units: Array[Unit] = []


func _next_turn() -> void:
	if board == null:
		return
	if check_victory() != -1:
		return
	# pega unidades vivas do time atual
	_team_units = board.get_units_by_team(_team_turn)
	if _team_units.is_empty():
		_switch_team()
		return
	if _unit_idx >= _team_units.size():
		_switch_team()
		return
	_current_unit = _team_units[_unit_idx]
	_unit_idx += 1
	turn_started.emit(_current_unit)
	EventBus.turn_changed.emit(_current_unit)


func _switch_team() -> void:
	_team_turn = 1 if _team_turn == 0 else 0
	_unit_idx = 0
	if _team_turn == 0:
		current_round += 1
		round_started.emit(current_round)
	_next_turn()
