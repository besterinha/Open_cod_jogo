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
	# busca CaravanManager se existir na cena
	var cm: CaravanManager = get_tree().get_first_node_in_group("caravan") as CaravanManager
	if cm:
		_label.text = "Dia %d | Supplies %d | Morale %d (%s) | Renown %d | Pop %d" % [cm.day, cm.supplies, cm.morale, cm.get_morale_state(), cm.renown, cm.total_pop()]
	else:
		_label.text = "Caravana: (sem CaravanManager na cena)"
