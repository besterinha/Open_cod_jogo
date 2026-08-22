class_name EventSystem
extends Node
# Data-driven: rola evento por peso/trigger, aplica escolha.

var caravan: CaravanManager
var _events: Array[EventResource] = []

signal event_rolled(event: EventResource)
signal choice_applied(event: EventResource, choice: EventChoice)

func setup(p_caravan: CaravanManager) -> void:
	caravan = p_caravan

func register_event(ev: EventResource) -> void:
	if ev != null and ev.is_valid():
		_events.append(ev)

func register_events(arr: Array[EventResource]) -> void:
	for e in arr:
		register_event(e)

func clear_events() -> void:
	_events.clear()

func load_from_data(path: String = "res://data/events/") -> void:
	# Carrega todos .tres em data/events/
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file: String = dir.get_next()
	while file != "":
		if file.ends_with(".tres") and not dir.current_is_dir():
			var ev: Resource = load(path + file)
			if ev is EventResource:
				register_event(ev as EventResource)
		file = dir.get_next()
	dir.list_dir_end()

func roll_random(trigger_filter: String = "random") -> EventResource:
	var pool: Array[EventResource] = []
	var total_weight: int = 0
	for ev in _events:
		if trigger_filter == "" or ev.trigger == trigger_filter:
			pool.append(ev)
			total_weight += max(1, ev.weight)
	if pool.is_empty():
		return null
	var roll: int = randi_range(1, total_weight)
	var accum: int = 0
	for ev in pool:
		accum += max(1, ev.weight)
		if roll <= accum:
			event_rolled.emit(ev)
			EventBus.event_triggered.emit(ev.id)
			return ev
	return pool.back()

func apply_choice(ev: EventResource, choice_idx: int) -> bool:
	if ev == null or choice_idx < 0 or choice_idx >= ev.escolhas.size():
		return false
	var choice: EventChoice = ev.escolhas[choice_idx]
	choice.apply(caravan)
	choice_applied.emit(ev, choice)
	return true
