extends Node3D
# Cena Jornada 1D side-scrolling placeholder (caravana).
# Integra Motor Caravana Fase 1: Travel/Camp/Market/Event.

@onready var caravan: Node = $CaravanManager
@onready var travel: Node = $TravelSystem
@onready var camp: Node = $CampSystem
@onready var market: Node = $MarketSystem
@onready var event_system: Node = $EventSystem
@onready var ui_bar: Control = $CanvasLayer/CaravanBar

var distance_traveled: float = 0.0
var last_action_outcome: String = ""  # observável p/ testes (§7b consumidor)


func _show_toast(texto: String) -> void:
	# feedback visível touch — prints não existem no device (TDD §4e)
	var layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if layer == null:
		return
	var lbl := Label.new()
	lbl.text = texto
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.modulate = Color(0.95, 0.95, 0.6)
	layer.add_child(lbl)
	lbl.reset_size()
	var vp_size: Vector2 = layer.get_viewport().get_visible_rect().size
	lbl.position = Vector2((vp_size.x - lbl.size.x) * 0.5, vp_size.y * 0.25)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: lbl.queue_free())


func _ready() -> void:
	# setup motor
	travel.setup(caravan)
	camp.setup(caravan)
	market.setup(caravan)
	event_system.setup(caravan)
	event_system.load_from_data()
	market.randomize_rate()
	print(
		(
			"[Journey] Dia %d | Supplies %d | Morale %s | Renown %d | Rate 1:%d"
			% [
				caravan.day,
				caravan.supplies,
				caravan.get_morale_state(),
				caravan.renown,
				market.current_rate
			]
		)
	)
	# conecta sinais para log
	travel.travel_day_completed.connect(_on_day)
	travel.travel_finished.connect(_on_travel_finished)
	EventBus.battle_requested.connect(_on_battle_requested)
	# integra radial menu touch (se existir)
	var radial: Node = get_node_or_null("CanvasLayer/RadialMenu")
	if radial and radial.has_signal("action_pressed"):
		radial.connect("action_pressed", _on_radial_action)


func _on_day(day: int) -> void:
	print(
		"[Journey] Dia %d completo. Supplies %d Morale %d" % [day, caravan.supplies, caravan.morale]
	)
	var ev: Resource = event_system.roll_random("random")
	if ev and randf() < 0.3:  # 30% chance
		print("[Event] %s: %s" % [ev.get("titulo"), ev.get("texto")])
		# aplica primeira escolha para teste
		if not ev.get("escolhas").is_empty():
			event_system.apply_choice(ev, 0)


func _on_travel_finished(_days: int) -> void:
	# 15% chance de batalha ao terminar viagem
	if randf() < 0.15:
		print("[Journey] Emboscada! Indo para combate...")
		EventBus.battle_requested.emit("ambush")


func _on_radial_action(action: String) -> void:
	last_action_outcome = ""
	match action:
		"viajar":
			travel.travel_one_day()
			last_action_outcome = "travel"
			_show_toast("Viajando... dia %d" % (caravan.day + 1))
		"descansar":
			camp.rest(1)
			last_action_outcome = "rest"
			_show_toast("Descansou (+moral, -suprimentos)")
		"mercado":
			market.buy_supplies(1)
			last_action_outcome = "market"
			print(
				(
					"[Market Touch] 1 Renown -> %d Supplies | supplies %d renown %d"
					% [market.current_rate, caravan.supplies, caravan.renown]
				)
			)
			_show_toast("Trocado 1 Renown -> %d Suprimentos" % market.current_rate)
		"evento":
			var ev: Resource = event_system.roll_random()
			if ev:
				print("[Event Touch] %s" % ev.get("titulo"))
				if not ev.get("escolhas").is_empty():
					event_system.apply_choice(ev, 0)
				last_action_outcome = "event:%s" % ev.get("id")
				_show_toast("Evento: %s" % ev.get("titulo"))
			else:
				last_action_outcome = "event:none"
				_show_toast("Nenhum evento no ar")
		"batalha":
			last_action_outcome = "battle_requested"
			EventBus.battle_requested.emit("radial_battle")
		_:
			last_action_outcome = "unknown:%s" % action
			_show_toast("Ação em breve: %s" % action)


func _on_battle_requested(_id: String) -> void:
	print("[Journey] Transição para Tático: %s" % _id)
	if get_tree().current_scene != self:
		return  # em teste/editor não troca a cena do runner
	get_tree().change_scene_to_file("res://content/maps/tactical_arena.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				travel.travel_one_day()
			KEY_R:
				camp.rest(1)
			KEY_M:
				market.buy_supplies(1)
				print(
					(
						"[Market] Comprou 1 Renown -> %d Supplies (rate 1:%d) | Agora supplies %d renown %d"
						% [
							market.current_rate,
							market.current_rate,
							caravan.supplies,
							caravan.renown
						]
					)
				)
			KEY_E:
				var ev: Resource = event_system.roll_random()
				if ev:
					print("[Event Manual] %s" % ev.get("titulo"))
			KEY_B:
				EventBus.battle_requested.emit("debug_battle")


func _process(delta: float) -> void:
	# side-scroll visual placeholder
	distance_traveled += delta * 2.0
	if has_node("CaravanVisual"):
		$CaravanVisual.position.x = fmod(distance_traveled, 10.0) - 5.0
