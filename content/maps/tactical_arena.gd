extends Node3D
# Cena 2.5D tática — Motor Genérico Completo.
# Integra: TacticalBoard + TurnManager + MovementSystem + CombatManager + AI

@onready var board: TacticalBoard = $TacticalBoard
@onready var turn_manager: TurnManager = $TurnManager
@onready var movement: MovementSystem = $MovementSystem
@onready var combat: CombatManager = $CombatManager

var selected_unit: Unit = null
var selected_ability: AbilityResource = null
var _db: AttributeDatabase = null

func _ready() -> void:
	# StatsRegistry (se existir)
	var reg: Node = get_node_or_null("/root/StatsRegistry")
	if reg and reg.has_method("get_db"):
		_db = reg.get_db()
	else:
		_db = load("res://data/stats/attributes.tres") as AttributeDatabase

	# Setup board
	board.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	board.grid_size = Vector2i(8, 8)
	# Remove placeholder grid, cria tiles visuais
	_spawn_tiles()
	_spawn_units()

	# Setup systems
	turn_manager.setup(board)
	movement.setup(board)
	combat.setup(board)

	# Integra HUD touch (se existir)
	var hud: Node = get_node_or_null("CanvasLayer/TacticalHUD")
	if hud:
		if hud.has_signal("ability_selected"):
			hud.connect("ability_selected", _on_hud_ability_selected)
		if hud.has_signal("end_turn_pressed"):
			hud.connect("end_turn_pressed", func() -> void: turn_manager.end_turn())
		# seleciona primeira habilidade como default
		if hud.has_method("get_selected"):
			selected_ability = hud.get_selected()

	# Conecta sinais
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.battle_ended.connect(_on_battle_ended)
	EventBus.turn_changed.connect(_on_turn_changed)

	print("[TacticalArena] Motor genérico pronto. Grid %s, Units %d" % [board.grid_size, board.units.size()])
	turn_manager.start_battle()

func _spawn_tiles() -> void:
	var container: Node3D = $TacticalBoard/Tiles
	if container == null:
		container = Node3D.new()
		container.name = "Tiles"
		board.add_child(container)
	for x in 8:
		for y in 8:
			var tile: Node3D = preload("res://placeholders/tactical/tile_cube.tscn").instantiate()
			tile.position = board.grid.cell_to_world(Vector2i(x, y))
			var mesh: MeshInstance3D = tile as MeshInstance3D
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.3, 0.3, 0.32) if ((x + y) % 2) == 0 else Color(0.25, 0.25, 0.27)
			mesh.material_override = mat
			container.add_child(tile)

func _spawn_units() -> void:
	# Player units
	for i in 2:
		var u := _create_unit("Hero%d" % (i+1), 0, Vector2i(i, 0), Color(0.2, 0.6, 1))
		board.add_unit(u)
	# Enemy units
	for i in 2:
		var u := _create_unit("Enemy%d" % (i+1), 1, Vector2i(6 + i % 2, 6 + i / 2), Color(1, 0.3, 0.3))
		board.add_unit(u)

func _create_unit(name: String, team: int, cell: Vector2i, col: Color) -> Unit:
	var unit := Unit.new()
	unit.unit_id = name.to_lower()
	unit.display_name = name
	unit.team = team
	unit.cell = cell
	unit.stats = UnitStats.new()
	unit.stats.values = {"hp": 10, "armor": 3, "willpower": 3, "movement": 4}
	if _db:
		for attr in _db.attributes:
			if not unit.stats.has_stat(attr.id):
				unit.stats.set_stat(attr.id, attr.default_value, _db)
	unit.position = board.grid.cell_to_world(cell)
	var body_mesh := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.0
	body_mesh.mesh = cap
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	body_mesh.material_override = mat
	body_mesh.name = "Visual"
	unit.add_child(body_mesh)
	var label := Label3D.new()
	label.text = "%s\nHP:%d" % [name, unit.get_stat("hp")]
	label.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	label.position = Vector3(0, 1.2, 0)
	label.font_size = 48
	label.name = "Label"
	unit.add_child(label)
	return unit

func _on_turn_started(unit: Unit) -> void:
	selected_unit = unit
	print("[Turn] Vez de %s (team %d) em %s" % [unit.display_name, unit.team, unit.cell])
	# destaca alcance
	_highlight_reachable(unit)
	# se for inimigo, AI joga após delay
	if unit.team == 1:
		await get_tree().create_timer(0.8).timeout
		_play_ai(unit)

func _play_ai(unit: Unit) -> void:
	var ai := preload("res://systems/tactical/ai/aggressive_ai.gd").new()
	ai.focus_stat_id = "hp"
	var intent: Dictionary = ai.generate_intent(unit, board)
	if intent.has("move_to"):
		var dest: Vector2i = intent["move_to"]
		if dest != unit.cell:
			print("[AI] %s move %s -> %s" % [unit.display_name, unit.cell, dest])
			movement.move_unit(unit, dest)
	if intent.has("target"):
		var target_cell: Vector2i = intent["target"]
		var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
		print("[AI] %s ataca %s com %s" % [unit.display_name, target_cell, abil.nome])
		combat.use_ability(unit, abil, target_cell)
	await get_tree().create_timer(0.5).timeout
	turn_manager.end_turn()

func _on_hud_ability_selected(abil: AbilityResource) -> void:
	selected_ability = abil
	print("[HUD] Habilidade selecionada touch: %s" % abil.nome)

func _on_turn_changed(unit: Unit) -> void:
	pass

func _on_battle_ended(winner: int) -> void:
	print("[Battle] Vitória do time %d!" % winner)
	EventBus.battle_requested.emit("victory_%d" % winner)
	await get_tree().create_timer(1.5).timeout
	if winner == 0:
		print("[Battle] Voltando para Jornada...")
		get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")
	else:
		print("[Battle] Derrota — Game Over (volta para jornada para teste)")
		get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")

func _highlight_reachable(unit: Unit) -> void:
	# limpa highlights antigos
	for c in get_tree().get_nodes_in_group("highlight"):
		c.queue_free()
	var reachable: Array[Vector2i] = movement.get_reachable(unit)
	for cell in reachable:
		var hl := MeshInstance3D.new()
		hl.mesh = BoxMesh.new()
		(hl.mesh as BoxMesh).size = Vector3(0.8, 0.05, 0.8)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 1, 0.3, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		hl.material_override = mat
		hl.position = board.grid.cell_to_world(cell) + Vector3(0, 0.02, 0)
		hl.add_to_group("highlight")
		$TacticalBoard.add_child(hl)

func _unhandled_input(event: InputEvent) -> void:
	var unit: Unit = turn_manager.get_current_unit()
	if unit == null or unit.team != 0:
		return # só player controla
	if event is InputEventScreenTouch and event.pressed:
		var cam: Camera3D = $Camera3D
		var from: Vector3 = cam.project_ray_origin(event.position)
		var dir: Vector3 = cam.project_ray_normal(event.position)
		if dir.y == 0:
			return
		var t: float = -from.y / dir.y
		var hit: Vector3 = from + dir * t
		var cell: Vector2i = board.grid.world_to_cell(hit)
		if not board.grid.is_within_bounds(cell):
			return
		print("[Input] Tap %s" % cell)
		# se tem unidade inimiga na cell, ataca com habilidade selecionada (touch) ou fallback strike
		var target_unit: Unit = board.get_unit_at(cell)
		if target_unit and target_unit.team != unit.team:
			var abil: AbilityResource = selected_ability
			if abil == null:
				abil = load("res://data/abilities/strike.tres") as AbilityResource
			if combat.use_ability(unit, abil, cell):
				print("[Combat Touch] %s usou %s em %s" % [unit.display_name, abil.nome, cell])
				turn_manager.end_turn()
			else:
				print("[Combat] Não pode usar %s em %s (alcance/custo)" % [abil.nome, cell])
		elif board.is_walkable(cell) or cell == unit.cell:
			# tenta mover
			if movement.can_move_to(unit, cell):
				movement.move_unit(unit, cell)
				print("[Move] %s -> %s" % [unit.display_name, cell])
				# após mover, pode atacar ou só passar turno? Aqui passa turno após mover para simplificar
				# turn_manager.end_turn()
				_highlight_reachable(unit)
			else:
				print("[Move] Não pode mover para %s" % cell)
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			turn_manager.end_turn()
		if event.keycode == KEY_J:
			# debug: transição para jornada
			get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")
