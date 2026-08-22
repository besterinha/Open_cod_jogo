extends Control
# UI isolada — só LE de CaravanManager, nunca escreve lógica.

@onready var _label: Label = $Label

func _ready() -> void:
	EventBus.supplies_changed.connect(_on_supplies)
	EventBus.morale_changed.connect(_on_morale)
	EventBus.day_passed.connect(_on_day)
	_update("init")

func _on_supplies(_v: int) -> void:
	_update("supplies")

func _on_morale(_v: int, _s: String) -> void:
	_update("morale")

func _on_day(_d: int) -> void:
	_update("day")

func _update(_reason: String) -> void:
	if not is_instance_valid(_label):
		return
	# busca CaravanManager se existir na cena (usa grupo ou busca na árvore)
	var cm: Node = get_tree().get_first_node_in_group("caravan")
	if cm == null:
		# tenta buscar no parent JourneyMap
		var root: Node = get_tree().current_scene
		if root and root.has_node("CaravanManager"):
			cm = root.get_node("CaravanManager")
	if cm:
		var day: int = int(cm.get("day"))
		var sup: int = int(cm.get("supplies"))
		var morale: int = int(cm.get("morale"))
		var ren: int = int(cm.get("renown"))
		var state: String = str(cm.call("get_morale_state"))
		var pop: int = int(cm.call("total_pop"))
		_label.text = "Dia %d | Supplies %d | Morale %d (%s) | Renown %d | Pop %d" % [day, sup, morale, state, ren, pop]
	else:
		_label.text = "Caravana: (sem CaravanManager na cena)"
