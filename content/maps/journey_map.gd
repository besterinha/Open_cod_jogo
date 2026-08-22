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

func _ready() -> void:
	# setup motor
	travel.setup(caravan)
	camp.setup(caravan)
	market.setup(caravan)
	event_system.setup(caravan)
	event_system.load_from_data()
	market.randomize_rate()
	print("[Journey] Dia %d | Supplies %d | Morale %s | Renown %d | Rate 1:%d" % [caravan.day, caravan.supplies, caravan.get_morale_state(), caravan.renown, market.current_rate])
	# conecta sinais para log
	travel.travel_day_completed.connect(_on_day)

func _on_day(day: int) -> void:
	print("[Journey] Dia %d completo. Supplies %d Morale %d" % [day, caravan.supplies, caravan.morale])
	var ev: Resource = event_system.roll_random("random")
	if ev and randf() < 0.3: # 30% chance
		print("[Event] %s: %s" % [ev.get("titulo"), ev.get("texto")])
		# aplica primeira escolha para teste
		if not ev.get("escolhas").is_empty():
			event_system.apply_choice(ev, 0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				travel.travel_one_day()
			KEY_R:
				camp.rest(1)
			KEY_M:
				market.buy_supplies(1)
				print("[Market] Comprou 1 Renown -> %d Supplies (rate 1:%d) | Agora supplies %d renown %d" % [market.current_rate, market.current_rate, caravan.supplies, caravan.renown])
			KEY_E:
				var ev: Resource = event_system.roll_random()
				if ev:
					print("[Event Manual] %s" % ev.get("titulo"))

func _process(delta: float) -> void:
	# side-scroll visual placeholder
	distance_traveled += delta * 2.0
	if has_node("CaravanVisual"):
		$CaravanVisual.position.x = fmod(distance_traveled, 10.0) - 5.0
