extends Control
# Radial menu simples touch — 5 fatias ao redor do botão central.
# Usado em Journey. Teclado continua funcionando para debug.

signal action_pressed(action: String)

@onready var center: Button = $Center
@onready var container: Control = $Actions

var _open: bool = false

func _ready() -> void:
	center.pressed.connect(_toggle)
	# conecta cada fatia
	for child in container.get_children():
		if child is Button:
			var btn: Button = child
			btn.pressed.connect(func() -> void: _on_action(btn.name))
	# começa fechado
	container.visible = false
	center.text = "☰"

func _toggle() -> void:
	_open = not _open
	container.visible = _open
	center.text = "✕" if _open else "☰"
	# posiciona fatias em círculo (raio 90)
	if _open:
		_layout_radial()

func _layout_radial() -> void:
	var radius: float = 90.0
	var actions: Array = container.get_children()
	var count: int = actions.size()
	for i in count:
		var btn: Control = actions[i] as Control
		var angle: float = (TAU * i / count) - PI/2.0 # começa em cima
		var pos: Vector2 = Vector2(cos(angle), sin(angle)) * radius
		# container está centrado no Center, então pos relativo
		btn.position = pos - btn.size * 0.5

func _on_action(action_name: String) -> void:
	# action_name = nome do botão (Viajar, Descansar...)
	action_pressed.emit(action_name.to_lower())
	_toggle() # fecha após escolher

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and _open:
		# se tocar fora do radial, fecha
		var rect: Rect2 = get_global_rect()
		if not rect.has_point(event.position):
			_toggle()
