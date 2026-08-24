class_name TurnManager
extends Node
# Interface base plugável — escolha implementação via Registry.

var board: TacticalBoard

signal turn_started(unit: Unit)
signal turn_ended(unit: Unit)
signal round_started(round: int)
signal battle_ended(winner_team: int)

var current_round: int = 0
var _current_unit: Unit = null
var _battle_over: bool = false


func setup(p_board: TacticalBoard) -> void:
	board = p_board


func get_current_unit() -> Unit:
	return _current_unit


func start_battle() -> void:
	current_round = 1
	round_started.emit(current_round)
	_next_turn()


func end_turn() -> void:
	if _current_unit:
		turn_ended.emit(_current_unit)
	_next_turn()


func _next_turn() -> void:
	push_warning("TurnManager base: sobrescreva _next_turn em subclasse plugável")


func check_victory() -> int:
	if board == null or _battle_over:
		return -1
	if board.is_victory(0):
		_battle_over = true
		battle_ended.emit(0)
		return 0
	if board.is_victory(1):
		_battle_over = true
		battle_ended.emit(1)
		return 1
	return -1
