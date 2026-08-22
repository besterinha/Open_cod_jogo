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
var _green_mat: StandardMaterial3D = null
var _blue_mat: StandardMaterial3D = null
var _highlight_box: BoxMesh = null
var _outline_mat: StandardMaterial3D = null
var _outline_box: BoxMesh = null
var _touch_start: Vector2 = Vector2.ZERO
var _is_drag: bool = false

func _ready() -> void:
	# StatsRegistry (se existir)
	var reg: Node = get_node_or_null("/root/StatsRegistry")
	if reg and reg.has_method("get_db"):
		_db = reg.get_db()
	else:
		_db = load("res://data/stats/attributes.tres") as AttributeDatabase

	# Setup board — fonte única é TacticalBoard.grid_size/cell_size (default 8x8 já no .tscn)
	board.grid = GridSystem.new(board.grid_size, board.cell_size)
	_spawn_tiles()
	_spawn_units()
	# sync CameraRig grid_limit com board
	var rig: Node = get_node_or_null("CameraRig")
	if rig and "grid_limit" in rig:
		rig.set("grid_limit", board.grid_size)
	# shared highlight materials/mesh (pooling) — Opção C máxima legibilidade
	_green_mat = StandardMaterial3D.new()
	_green_mat.albedo_color = Color(0.1, 1, 0.2, 0.85)
	_green_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_green_mat.emission_enabled = true
	_green_mat.emission = Color(0.2, 1, 0.3)
	_green_mat.emission_energy_multiplier = 1.5
	_blue_mat = StandardMaterial3D.new()
	_blue_mat.albedo_color = Color(0.25, 0.55, 1, 0.85)
	_blue_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_blue_mat.emission_enabled = true
	_blue_mat.emission = Color(0.3, 0.5, 1)
	_blue_mat.emission_energy_multiplier = 1.5
	_highlight_box = BoxMesh.new()
	_highlight_box.size = Vector3(0.92, 0.08, 0.92)
	_outline_mat = StandardMaterial3D.new()
	_outline_mat.albedo_color = Color(0, 0, 0, 0.3)
	_outline_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_outline_box = BoxMesh.new()
	_outline_box.size = Vector3(1.0, 0.04, 1.0)

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

	# VFX: escuta combat
	combat.ability_used.connect(_on_ability_used)
	combat.damage_applied.connect(_on_damage_applied)

	# Conecta sinais
	turn_manager.turn_started.connect(_on_turn_started)
	turn_manager.battle_ended.connect(_on_battle_ended)
	EventBus.turn_changed.connect(_on_turn_changed)

	print("[TacticalArena] Motor genérico pronto. Grid %s, Units %d" % [board.grid_size, board.units.size()])
	turn_manager.start_battle()

var _light_mat: StandardMaterial3D = null
var _dark_mat: StandardMaterial3D = null

func _ensure_tile_mats() -> void:
	if _light_mat == null:
		_light_mat = StandardMaterial3D.new()
		_light_mat.albedo_color = Color(0.58, 0.56, 0.52)
	if _dark_mat == null:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.44, 0.42, 0.39)

func _spawn_tiles() -> void:
	_ensure_tile_mats()
	var container: Node3D = $TacticalBoard/Tiles
	if container == null:
		container = Node3D.new()
		container.name = "Tiles"
		board.add_child(container)
	for x in board.grid_size.x:
		for y in board.grid_size.y:
			var tile: Node3D = preload("res://placeholders/tactical/tile_cube.tscn").instantiate()
			tile.position = board.grid.cell_to_world(Vector2i(x, y))
			var mesh: MeshInstance3D = tile as MeshInstance3D
			mesh.material_override = _light_mat if ((x + y) % 2) == 0 else _dark_mat
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
	_update_turn_label(unit)
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
	if selected_unit:
		_highlight_reachable(selected_unit)

func _on_ability_used(user: Unit, abil: AbilityResource, cells: Array[Vector2i]) -> void:
	_spawn_vfx(abil, cells)

func _spawn_vfx(abil: AbilityResource, cells: Array[Vector2i]) -> void:
	var scene: PackedScene = abil.vfx
	if scene == null:
		scene = preload("res://placeholders/vfx/vfx_circle.tscn")
	for cell in cells:
		var v: Node3D = scene.instantiate() as Node3D
		v.position = board.grid.cell_to_world(cell) + Vector3(0, 0.15, 0)
		# cor por tipo: dano vermelho, heal verde
		if not abil.efeitos.is_empty():
			var delta: int = int(abil.efeitos[0].get("delta", 0))
			if delta > 0:
				# heal = verde
				var m: StandardMaterial3D = StandardMaterial3D.new()
				m.albedo_color = Color(0.3, 1, 0.4, 0.6)
				m.emission = Color(0.3, 1, 0.4)
				m.emission_energy_multiplier = 2.0
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				var mesh_node: MeshInstance3D = v as MeshInstance3D
				if mesh_node:
					mesh_node.material_override = m
		$TacticalBoard.add_child(v)
		var tw: Tween = create_tween()
		tw.tween_property(v, "scale", Vector3(2, 2, 2), 0.4)
		tw.parallel().tween_property(v, "position:y", v.position.y + 0.5, 0.4)
		tw.tween_callback(func() -> void: v.queue_free())

func _on_damage_applied(target: Unit, effects: Array) -> void:
	for eff in effects:
		var sid: String = str(eff.get("stat_id", ""))
		var delta: int = int(eff.get("delta", 0))
		if sid == "hp":
			_spawn_damage_number(target, delta)

func _spawn_damage_number(unit: Unit, delta: int) -> void:
	var lbl := Label3D.new()
	lbl.text = ("%+d" % delta) if delta < 0 else ("+%d" % delta)
	lbl.modulate = Color(1, 0.3, 0.3) if delta < 0 else Color(0.3, 1, 0.4)
	lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	lbl.font_size = 64
	lbl.outline_size = 10
	lbl.position = unit.position + Vector3(0, 1.8, 0)
	add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_property(lbl, "position:y", lbl.position.y + 1.0, 0.8)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.tween_callback(func() -> void: lbl.queue_free())

func _on_turn_changed(unit: Unit) -> void:
	_update_turn_label(unit)

func _update_turn_label(unit: Unit) -> void:
	var label: Label = get_node_or_null("CanvasLayer/TurnLabel") as Label
	if label:
		var round: int = turn_manager.current_round if turn_manager else 1
		label.text = "Turno: %s (T%d) R%d" % [unit.display_name, unit.team, round]
		label.modulate = Color(0.2, 0.6, 1) if unit.team == 0 else Color(1, 0.4, 0.4)
	# destaca unidade ativa
	for u in board.units:
		var vis: Node = u.get_node_or_null("Visual")
		if vis and vis is MeshInstance3D:
			var mat: StandardMaterial3D = (vis as MeshInstance3D).material_override as StandardMaterial3D
			if mat:
				mat.emission_enabled = (u == unit)
				if u == unit:
					mat.emission = Color(1, 0.9, 0.3)
					mat.emission_energy_multiplier = 1.5
				else:
					mat.emission = Color(0, 0, 0)
					mat.emission_energy_multiplier = 0.0

func _on_battle_ended(winner: int) -> void:
	print("[Battle] Vitória do time %d!" % winner)
	_clear_highlights()
	EventBus.battle_requested.emit("victory_%d" % winner)
	await get_tree().create_timer(1.5).timeout
	if winner == 0:
		print("[Battle] Voltando para Jornada...")
		get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")
	else:
		print("[Battle] Derrota — Game Over (volta para jornada para teste)")
		get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")

func _clear_highlights() -> void:
	for c in get_tree().get_nodes_in_group("highlight"):
		c.queue_free()
	for c in get_tree().get_nodes_in_group("highlight_abil"):
		c.queue_free()
	for c in get_tree().get_nodes_in_group("highlight_outline"):
		c.queue_free()

func _highlight_reachable(unit: Unit) -> void:
	# menos poluição: verde = movimento, azul = alcance da habilidade (só se selecionada, sem sobrepor verde)
	_clear_highlights()
	if unit == null or unit.is_defeated():
		return
	var reachable: Array[Vector2i] = movement.get_reachable(unit)
	for cell in reachable:
		# outline preto por baixo
		var ol := MeshInstance3D.new()
		ol.mesh = _outline_box
		ol.material_override = _outline_mat
		ol.position = board.grid.cell_to_world(cell) + Vector3(0, 0.015, 0)
		ol.add_to_group("highlight_outline")
		$TacticalBoard.add_child(ol)
		var hl := MeshInstance3D.new()
		hl.mesh = _highlight_box
		hl.material_override = _green_mat
		hl.position = board.grid.cell_to_world(cell) + Vector3(0, 0.035, 0)
		hl.add_to_group("highlight")
		$TacticalBoard.add_child(hl)
	# alcance da habilidade selecionada em azul (menos poluído: só se selecionada)
	if selected_ability:
		var abil_reach: Array[Vector2i] = board.grid.get_reachable(unit.cell, selected_ability.alcance, func(c: Vector2i) -> bool: return board.grid.is_within_bounds(c))
		for cell in abil_reach:
			if reachable.has(cell):
				continue # já verde, não poluir
			var ol2 := MeshInstance3D.new()
			ol2.mesh = _outline_box
			ol2.material_override = _outline_mat
			ol2.position = board.grid.cell_to_world(cell) + Vector3(0, 0.015, 0)
			ol2.add_to_group("highlight_outline")
			$TacticalBoard.add_child(ol2)
			var hl2 := MeshInstance3D.new()
			hl2.mesh = _highlight_box
			hl2.material_override = _blue_mat
			hl2.position = board.grid.cell_to_world(cell) + Vector3(0, 0.035, 0)
			hl2.add_to_group("highlight_abil")
			$TacticalBoard.add_child(hl2)

func _handle_tap(pos: Vector2) -> void:
	var unit: Unit = turn_manager.get_current_unit()
	if unit == null or unit.team != 0:
		return
	var cam: Camera3D = get_node_or_null("CameraRig/Camera3D") as Camera3D
	if cam == null:
		cam = get_node_or_null("Camera3D") as Camera3D
	if cam == null:
		return
	var from: Vector3 = cam.project_ray_origin(pos)
	var dir: Vector3 = cam.project_ray_normal(pos)
	if dir.y == 0:
		return
	var t: float = -from.y / dir.y
	var hit: Vector3 = from + dir * t
	var cell: Vector2i = board.grid.world_to_cell(hit)
	if not board.grid.is_within_bounds(cell):
		return
	print("[Input] Tap %s" % cell)
	var target_unit: Unit = board.get_unit_at(cell)
	if target_unit:
		var abil: AbilityResource = selected_ability
		if abil == null:
			abil = load("res://data/abilities/strike.tres") as AbilityResource
		if combat.use_ability(unit, abil, cell):
			print("[Combat Touch] %s usou %s em %s" % [unit.display_name, abil.nome, cell])
			turn_manager.end_turn()
		else:
			print("[Combat] Não pode usar %s em %s (alcance/custo %s)" % [abil.nome, cell, abil.custo])
	elif board.is_walkable(cell) or cell == unit.cell:
		if movement.can_move_to(unit, cell):
			movement.move_unit(unit, cell)
			print("[Move] %s -> %s" % [unit.display_name, cell])
			_highlight_reachable(unit)
		else:
			print("[Move] Não pode mover para %s" % cell)

func _unhandled_input(event: InputEvent) -> void:
	# Touch drag vs tap (threshold 10px) — evita conflito com CameraRig pan
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_is_drag = false
		else:
			# release — só considera tap se não arrastou
			if not _is_drag and _touch_start.distance_to(event.position) < 10.0:
				_handle_tap(event.position)
			_is_drag = false
		return
	if event is InputEventScreenDrag:
		if _touch_start.distance_to(event.position) > 10.0:
			_is_drag = true
		return # deixa CameraRig lidar com pan
	# Mouse para debug PC
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			turn_manager.end_turn()
		elif event.keycode == KEY_J:
			get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")
