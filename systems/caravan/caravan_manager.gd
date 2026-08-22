extends Node
class_name CaravanManager
# Sistema plugável de recursos da caravana (Banner Saga-like).
# ICaravanResourceSystem default simples (1 supply = 1 dia). Trocar lógica = trocar este arquivo.
# 100% gratuito, sem dependência de content.

signal updated(data: Dictionary)

var day: int = 1
var supplies: int = 30
var morale: int = 50 # 0..100
var renown: int = 0
var pop: Dictionary = {"clansmen": 100, "fighters": 30, "varl": 10}

const MORALE_STATES: Array[String] = ["miserable", "low", "normal", "good", "great"]

func get_morale_state() -> String:
	if morale < 20: return "miserable"
	if morale < 40: return "low"
	if morale < 60: return "normal"
	if morale < 80: return "good"
	return "great"

func total_pop() -> int:
	return int(pop["clansmen"]) + int(pop["fighters"]) + int(pop["varl"])

# Fórmula plugável: default simples 1 supply/dia. Alternativa banner saga: ceil(total_pop/100)/dia
func consume_day() -> void:
	day += 1
	supplies = max(0, supplies - 1)
	morale = max(0, morale - 10)
	EventBus.day_passed.emit(day)
	EventBus.supplies_changed.emit(supplies)
	EventBus.morale_changed.emit(morale, get_morale_state())
	updated.emit(get_data())
	if supplies == 0:
		morale = max(0, morale - 5) # penalidade extra sem comida

func rest_day() -> void:
	day += 1
	supplies = max(0, supplies - 1) # ainda consome
	if supplies > 0:
		morale = min(100, morale + 10)
	EventBus.day_passed.emit(day)
	EventBus.supplies_changed.emit(supplies)
	EventBus.morale_changed.emit(morale, get_morale_state())
	updated.emit(get_data())

func add_supplies(v: int) -> void:
	supplies += v
	EventBus.supplies_changed.emit(supplies)
	updated.emit(get_data())

func add_morale(v: int) -> void:
	morale = clamp(morale + v, 0, 100)
	EventBus.morale_changed.emit(morale, get_morale_state())
	updated.emit(get_data())

func add_renown(v: int) -> void:
	renown += v
	EventBus.renown_changed.emit(renown)
	updated.emit(get_data())

func get_data() -> Dictionary:
	return {"day": day, "supplies": supplies, "morale": morale, "renown": renown, "pop": pop.duplicate(), "morale_state": get_morale_state()}
