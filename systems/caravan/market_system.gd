class_name MarketSystem
extends Node
# Plugável: troca Renown <-> Supplies com taxa variável.

var caravan: CaravanManager

## Taxa: 1 Renown = X Supplies. Quanto maior X, melhor para jogador.
@export var current_rate: int = 5
@export var min_rate: int = 3
@export var max_rate: int = 12

signal exchanged(renown_spent: int, supplies_gained: int, new_rate: int)
signal exchange_failed(reason: String)

func setup(p_caravan: CaravanManager) -> void:
	caravan = p_caravan

func set_rate(rate: int) -> void:
	current_rate = clamp(rate, min_rate, max_rate)

func randomize_rate() -> void:
	current_rate = randi_range(min_rate, max_rate)

func can_buy_supplies(renown_cost: int = 1) -> bool:
	return caravan != null and caravan.renown >= renown_cost

func buy_supplies(renown_cost: int = 1) -> bool:
	if not can_buy_supplies(renown_cost):
		exchange_failed.emit("Renown insuficiente")
		return false
	var supplies_gained: int = renown_cost * current_rate
	caravan.renown -= renown_cost
	caravan.supplies += supplies_gained
	EventBus.renown_changed.emit(caravan.renown)
	EventBus.supplies_changed.emit(caravan.supplies)
	exchanged.emit(renown_cost, supplies_gained, current_rate)
	return true

func buy_supplies_amount(supplies_wanted: int) -> bool:
	# calcula renown necessário (arredonda pra cima)
	var cost: int = int(ceil(float(supplies_wanted) / current_rate))
	return buy_supplies(cost)

func get_preview(supplies_wanted: int) -> Dictionary:
	return {
		"supplies": supplies_wanted,
		"cost_renown": int(ceil(float(supplies_wanted) / current_rate)),
		"rate": current_rate
	}
