extends Resource
class_name EventChoice

@export var label: String = ""
@export var cost: Dictionary = {} # {supplies: 20, morale: -10}
@export var reward: Dictionary = {} # {renown: 5, supplies: 10, morale: 5}
@export var requer_tag: String = ""

func apply(caravan: CaravanManager) -> void:
	for k in cost.keys():
		match k:
			"supplies": caravan.supplies = max(0, caravan.supplies - int(cost[k]))
			"morale": caravan.add_morale(-int(cost[k]))
			"renown": caravan.add_renown(-int(cost[k]))
	for k in reward.keys():
		match k:
			"supplies": caravan.add_supplies(int(reward[k]))
			"morale": caravan.add_morale(int(reward[k]))
			"renown": caravan.add_renown(int(reward[k]))
			_ : pass
