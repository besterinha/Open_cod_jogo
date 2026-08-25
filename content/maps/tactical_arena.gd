class_name TacticalArena
extends Node3D
# Cena 2.5D tática — Motor Genérico Completo.
# Integra: TacticalBoard + TurnManager + MovementSystem + CombatManager + AI

@onready var board: TacticalBoard = $TacticalBoard
@onready var turn_manager: TurnManager = $TurnManager
@onready var movement: MovementSystem = $MovementSystem
@onready var combat: CombatManager = $CombatManager

# Nível 3 export-safe (TDD §4e): layout embutido em código — script SEMPRE viaja no PCK,
# então obstáculos são garantidos mesmo se .tscn ext_resource e load(.tres) falharem no device.
const FALLBACK_SIZE := Vector2i(8, 8)
const FALLBACK_DAMAGE := -2
const FALLBACK_ROWS: PackedStringArray = [
	"........",
	"..##....",
	"..##..3.",
	"........",
	"....^...",
	"...44...",
	"........",
	"........",
]

var selected_unit: Unit = null
var selected_ability: AbilityResource = null
var moves_left: int = 1  # 1 movimento por turno (GDD: Mover + Ação)
var terrain_level: String = "?"  # L1=.tscn | L2=load(.tres) | L3=código
var _db: AttributeDatabase = null
var _green_mat: StandardMaterial3D = null
var _blue_mat: StandardMaterial3D = null
var _highlight_box: BoxMesh = null
var _outline_mat: StandardMaterial3D = null
var _outline_box: BoxMesh = null
var _turn_arrow: Node3D = null
var _arrow_tween: Tween = null
var _touch_start: Vector2 = Vector2.ZERO
var _is_drag: bool = false
var _long_press_index: int = -1
var _long_press_handled: bool = false


func _ready() -> void:
	# StatsRegistry (se existir)
	var reg: Node = get_node_or_null("/root/StatsRegistry")
	if reg and reg.has_method("get_db"):
		_db = reg.get_db()
	else:
		_db = load("res://data/stats/attributes.tres") as AttributeDatabase

	# Setup board — fonte única é TacticalBoard.grid_size/cell_size (default 8x8 já no .tscn)
	board.grid = GridSystem.new(board.grid_size, board.cell_size)
	var terrain_node: TerrainLayer = get_node_or_null("TerrainLayer") as TerrainLayer
	if terrain_node == null:
		# export-safe: script do node pode não bindar no PCK — recria a camada em código (L3)
		terrain_node = TerrainLayer.new()
		terrain_node.name = "TerrainLayer"
		add_child(terrain_node)
	var loaded: Resource = load("res://data/maps/tactical_arena.tres")
	var resolved: BoardLayoutResource = _resolve_layout(terrain_node.layout, loaded)
	terrain_node.layout = resolved
	board.terrain = terrain_node
	_spawn_tiles()
	_spawn_units()
	_update_diag_label()
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
	_ensure_turn_arrow()

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
			hud.connect("end_turn_pressed", _request_end_turn)
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
	# vitória responsiva: derrota imediata consulta check_victory (guarda anti-duplo-emissão no TurnManager)
	board.unit_added.connect(
		func(u: Unit) -> void:
			u.unit_defeated.connect(func(_x: Unit) -> void: turn_manager.check_victory())
	)
	for u in board.units:
		u.unit_defeated.connect(func(_x: Unit) -> void: turn_manager.check_victory())

	print(
		(
			"[TacticalArena] Motor genérico pronto. Grid %s, Units %d"
			% [board.grid_size, board.units.size()]
		)
	)
	turn_manager.start_battle()


var _light_mat: StandardMaterial3D = null
var _dark_mat: StandardMaterial3D = null


func _exit_tree() -> void:
	# evita "Infinite loop detected" do bob set_loops após free da cena (vazava p/ testes)
	if _arrow_tween:
		_arrow_tween.kill()


static func make_fallback_layout() -> BoardLayoutResource:
	var l := BoardLayoutResource.new()
	l.size = FALLBACK_SIZE
	l.rows = FALLBACK_ROWS
	l.damage_delta = FALLBACK_DAMAGE
	return l


static func _layout_tem_conteudo(l: BoardLayoutResource) -> bool:
	# export descoberta 0.3.1: conversão text->binário pode entregar o .tres COM script
	# mas SEM rows (objeto default). Validar CONTEÚDO, não só !=null.
	return l != null and not l.rows.is_empty()


func _resolve_layout(node_layout: BoardLayoutResource, loaded: Resource) -> BoardLayoutResource:
	# Cadeia export-safe: L1 ext_resource (.tscn) → L2 load(.tres) → L3 const em código
	if _layout_tem_conteudo(node_layout):
		terrain_level = "L1"
		return node_layout
	if loaded is BoardLayoutResource and _layout_tem_conteudo(loaded as BoardLayoutResource):
		if node_layout != null:
			push_warning(
				"[TacticalArena] layout do .tscn chegou vazio no pacote — usando .tres (L2)"
			)
		terrain_level = "L2"
		return loaded as BoardLayoutResource
	push_warning("[TacticalArena] .tres sem conteúdo no pacote — usando layout embutido (L3)")
	terrain_level = "L3"
	return make_fallback_layout()


func _update_diag_label() -> void:
	var layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
	if layer == null:
		return
	var lbl: Label = layer.get_node_or_null("DiagLabel") as Label
	if lbl == null:
		lbl = Label.new()
		lbl.name = "DiagLabel"
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.position = Vector2(430, 8)
		layer.add_child(lbl)
	var walls := 0
	var floors := 0
	var costs := 0
	for x in board.terrain.layout.size.x:
		for y in board.terrain.layout.size.y:
			match board.terrain.layout.token_at(Vector2i(x, y)):
				"#":
					walls += 1
				"^":
					floors += 1
				"2", "3", "4", "5", "6", "7", "8", "9":
					costs += 1
	var ver: String = str(ProjectSettings.get_setting("application/config/version", "dev"))
	var abil_count: int = -1
	var hud: Node = get_node_or_null("CanvasLayer/TacticalHUD")
	if hud != null and hud.has_method("get_loaded_count"):
		abil_count = hud.get_loaded_count()
	lbl.text = (
		"%s | terreno:%s muros:%d espinho:%d custo:%d | abil:%d"
		% [ver, terrain_level, walls, floors, costs, abil_count]
	)
	lbl.modulate = Color(0.15, 0.15, 0.15)


func _ensure_tile_mats() -> void:
	if _light_mat == null:
		_light_mat = StandardMaterial3D.new()
		_light_mat.albedo_color = Color(0.96, 0.96, 0.96)
		_light_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if _dark_mat == null:
		_dark_mat = StandardMaterial3D.new()
		_dark_mat.albedo_color = Color(0.86, 0.86, 0.86)
		_dark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _ensure_turn_arrow() -> void:
	if _turn_arrow != null:
		return
	# tenta carregar placeholder .tscn se existir, senão cria Label3D 2D fallback
	var arrow_scene: PackedScene = (
		load("res://placeholders/tactical/arrow_indicator.tscn") as PackedScene
	)
	if arrow_scene != null:
		_turn_arrow = arrow_scene.instantiate() as Node3D
	else:
		_turn_arrow = Node3D.new()
		var lbl := Label3D.new()
		lbl.text = "▼"
		lbl.font_size = 96
		lbl.modulate = Color(1, 0.92, 0.25)
		lbl.outline_size = 12
		lbl.outline_modulate = Color(0, 0, 0, 0.9)
		lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		lbl.position = Vector3(0, 0, 0)
		lbl.name = "ArrowLabel"
		_turn_arrow.add_child(lbl)
	_turn_arrow.name = "TurnArrow"
	_turn_arrow.visible = false
	add_child(_turn_arrow)


func _update_turn_arrow(unit: Unit) -> void:
	if _turn_arrow == null:
		_ensure_turn_arrow()
	if unit == null or unit.is_defeated():
		_turn_arrow.visible = false
		return
	# reparent para a unidade da vez — voando acima da cabeça
	if _turn_arrow.get_parent() != unit:
		_turn_arrow.reparent(unit)
	_turn_arrow.position = Vector3(0, 1.9, 0)
	_turn_arrow.visible = true
	# bobbing tween — seta 2D voando
	if _arrow_tween:
		_arrow_tween.kill()
	_arrow_tween = create_tween()
	_arrow_tween.set_loops()
	(
		_arrow_tween
		. tween_property(_turn_arrow, "position:y", 1.9 + 0.15, 0.6)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)
	(
		_arrow_tween
		. tween_property(_turn_arrow, "position:y", 1.9, 0.6)
		. set_trans(Tween.TRANS_SINE)
		. set_ease(Tween.EASE_IN_OUT)
	)


func _spawn_tiles() -> void:
	_ensure_tile_mats()
	# materiais de terreno (placeholder unshaded): bloqueado escuro, dano laranja
	var blocked_mat := StandardMaterial3D.new()
	blocked_mat.albedo_color = Color(0.22, 0.22, 0.26)
	blocked_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var damage_mat := StandardMaterial3D.new()
	damage_mat.albedo_color = Color(1.0, 0.45, 0.2, 0.9)
	damage_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var container: Node3D = $TacticalBoard/Tiles
	if container == null:
		container = Node3D.new()
		container.name = "Tiles"
		board.add_child(container)
	for x in board.grid_size.x:
		for y in board.grid_size.y:
			var cell := Vector2i(x, y)
			var tile: Node3D = preload("res://placeholders/tactical/tile_cube.tscn").instantiate()
			tile.position = board.grid.cell_to_world(cell)
			var mesh: MeshInstance3D = tile as MeshInstance3D
			if mesh:
				if board.terrain != null and board.terrain.is_blocked(cell):
					mesh.material_override = blocked_mat
				elif board.terrain != null and board.terrain.layout.is_damage_floor(cell):
					mesh.material_override = damage_mat
				else:
					mesh.material_override = _light_mat if ((x + y) % 2) == 0 else _dark_mat
			else:
				push_warning("[TacticalArena] tile_cube root não é MeshInstance3D")
			container.add_child(tile)


func _spawn_units() -> void:
	# Player units — pastel unshaded máxima visibilidade (Redmi)
	for i in 2:
		var u := _create_unit("Hero%d" % (i + 1), 0, Vector2i(i, 0), Color(0.60, 0.85, 1.0))
		board.add_unit(u)
	# Enemy units
	for i in 2:
		var u := _create_unit(
			"Enemy%d" % (i + 1), 1, Vector2i(6 + i % 2, 6 + i / 2), Color(1.0, 0.60, 0.60)
		)
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
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
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
	moves_left = 1  # reseta 1 movimento/turno
	_update_turn_label(unit)
	print("[Turn] Vez de %s (team %d) em %s" % [unit.display_name, unit.team, unit.cell])
	# destaca alcance
	_highlight_reachable(unit)
	# se for inimigo, AI joga após delay
	if unit.team == 1:
		await get_tree().create_timer(0.8).timeout
		if not is_inside_tree() or not is_instance_valid(unit) or unit.is_defeated():
			return
		_play_ai(unit)


func _request_end_turn() -> void:
	# regression endturn_spam: só o jogador passa a PRÓPRIA vez — nunca pula a IA
	var u: Unit = turn_manager.get_current_unit()
	if u == null or turn_manager.is_battle_over():
		return
	if u.team != 0:
		var hud0: Node = get_node_or_null("CanvasLayer/TacticalHUD")
		if hud0:
			hud0.show_toast("Não é a sua vez", true)
		return
	if movement.is_moving(u):
		var hud1: Node = get_node_or_null("CanvasLayer/TacticalHUD")
		if hud1:
			hud1.show_toast("Aguarde o movimento terminar", true)
		return
	turn_manager.end_turn()


func _play_ai(unit: Unit) -> void:
	var ai := preload("res://systems/tactical/ai/aggressive_ai.gd").new()
	ai.focus_stat_id = "hp"
	var intent: Dictionary = ai.generate_intent(unit, board)
	if intent.has("move_to"):
		var dest: Vector2i = intent["move_to"]
		if dest != unit.cell and movement.move_unit(unit, dest):
			print("[AI] %s move %s -> %s" % [unit.display_name, unit.cell, dest])
			# pacing: espera a animação terminar antes de agir/passar a vez
			while movement.is_moving(unit):
				if not is_inside_tree() or not is_instance_valid(unit):
					return
				await get_tree().process_frame
	if intent.has("target"):
		var target_cell: Vector2i = intent["target"]
		var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
		print("[AI] %s ataca %s com %s" % [unit.display_name, target_cell, abil.nome])
		combat.use_ability(unit, abil, target_cell)
	await get_tree().create_timer(0.3).timeout
	if not is_inside_tree():
		return
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
	# seta 2D voando indica vez — sem dim amarelo (puro)
	_update_turn_arrow(unit)


func _on_battle_ended(winner: int) -> void:
	print("[Battle] Vitória do time %d!" % winner)
	_clear_highlights()
	if _turn_arrow:
		_turn_arrow.visible = false
	if _arrow_tween:
		_arrow_tween.kill()
	EventBus.battle_requested.emit("victory_%d" % winner)
	await get_tree().create_timer(1.5).timeout
	print("[Battle] %s — voltando para Jornada..." % ("Vitória" if winner == 0 else "Derrota"))
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
		var abil_reach: Array[Vector2i] = board.grid.get_reachable(
			unit.cell,
			selected_ability.alcance,
			func(c: Vector2i) -> bool: return board.grid.is_within_bounds(c)
		)
		for cell in abil_reach:
			if reachable.has(cell):
				continue  # já verde, não poluir
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


func _try_use_ability(unit: Unit, cell: Vector2i, hud: Node) -> bool:
	# fluxo comum de uso + toasts visíveis (prints não existem no device)
	if combat.can_use_ability(unit, selected_ability, cell):
		if combat.use_ability(unit, selected_ability, cell):
			print(
				"[Combat Touch] %s usou %s em %s" % [unit.display_name, selected_ability.nome, cell]
			)
			turn_manager.end_turn()
			return true
		print("[Combat] Falha use_ability %s em %s" % [selected_ability.nome, cell])
		if hud:
			hud.show_toast("Falha ao usar %s" % selected_ability.nome, true)
		return false
	print(
		(
			"[Combat] Não pode usar %s em %s (alcance/custo %s)"
			% [selected_ability.nome, cell, selected_ability.custo]
		)
	)
	if hud:
		hud.show_toast("%s: fora de alcance ou sem recurso" % selected_ability.nome, true)
	return false


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
	var hud: Node = get_node_or_null("CanvasLayer/TacticalHUD")
	# cura em si (regression heal_ally): alvo != "inimigo" permite tap no próprio tile
	if cell == unit.cell and selected_ability != null and selected_ability.alvo != "inimigo":
		if _try_use_ability(unit, cell, hud):
			return
		return  # falha já notificada com toast
	if cell == unit.cell:
		print("[Input] Tap próprio tile, ignora")
		return
	# intenção de uso respeita AbilityResource.alvo (data-driven):
	var alvo_valido := false
	if target_unit != null and selected_ability != null:
		match selected_ability.alvo:
			"inimigo":
				alvo_valido = target_unit.team != unit.team
			"aliado":
				alvo_valido = target_unit.team == unit.team
			"qualquer":
				alvo_valido = true
	if alvo_valido:
		if _try_use_ability(unit, cell, hud):
			return
		return  # falha já notificada com toast
	# se tem unidade (aliada ou sem habilidade), não explode — ignora ataque
	if target_unit:
		print("[Input] Unidade aliada/própria em %s, sem ataque (sem explosão)" % cell)
		return
	if board.is_walkable(cell):
		# lock anti-stack: ignora tap durante animação de movimento
		if movement.is_moving(unit):
			print("[Input] %s ainda movendo, tap ignorado" % unit.display_name)
			return
		# 1 movimento por turno (GDD: Mover + Ação)
		if moves_left <= 0:
			print("[Input] Sem movimentos neste turno — use habilidade ou Passar Turno")
			if hud:
				hud.show_toast("Sem movimentos neste turno", true)
			return
		if movement.can_move_to(unit, cell):
			if movement.move_unit(unit, cell):
				moves_left -= 1
				print("[Move] %s -> %s (%d restantes)" % [unit.display_name, cell, moves_left])
				if moves_left <= 0:
					for c in get_tree().get_nodes_in_group("highlight"):
						c.queue_free()  # limpa verde; mantém azul da habilidade
			else:
				print("[Move] Não pode mover para %s" % cell)


func _show_unit_info(pos: Vector2) -> void:
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
	var unit: Unit = board.get_unit_at(cell)
	if unit:
		print(
			(
				"[LongPress] %s | %s | HP:%d | Team %d"
				% [unit.display_name, unit.cell, unit.get_stat("hp"), unit.team]
			)
		)
		# feedback visual rápido (Label3D info)
		var lbl := Label3D.new()
		lbl.text = "%s\nHP:%d\n%s" % [unit.display_name, unit.get_stat("hp"), unit.cell]
		lbl.modulate = Color(1, 1, 0.6)
		lbl.outline_size = 10
		lbl.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		lbl.position = unit.position + Vector3(0, 2.0, 0)
		add_child(lbl)
		var tw: Tween = create_tween()
		tw.tween_property(lbl, "modulate:a", 0.0, 1.2)
		tw.tween_callback(func() -> void: lbl.queue_free())
	else:
		print("[LongPress] vazio em %s" % cell)


func _unhandled_input(event: InputEvent) -> void:
	# Pinch zoom — deixa CameraRig lidar, não marca drag
	if event is InputEventMagnifyGesture:
		return
	# Touch drag vs tap + long-press (0.6s) (C6)
	if event is InputEventScreenTouch:
		if event.pressed:
			_touch_start = event.position
			_is_drag = false
			_long_press_handled = false
			_long_press_index = event.index
			# timer long-press 0.6s
			var idx: int = event.index
			var pos: Vector2 = event.position
			get_tree().create_timer(0.6).timeout.connect(
				func() -> void:
					if _long_press_index == idx and not _is_drag and not _long_press_handled:
						if _touch_start.distance_to(pos) < 10.0:
							_long_press_handled = true
							_show_unit_info(pos)
			)
		else:
			if _long_press_index == event.index:
				_long_press_index = -1
			if _long_press_handled:
				_long_press_handled = false
				_is_drag = false
				return
			# release — só considera tap se não arrastou
			if not _is_drag and _touch_start.distance_to(event.position) < 10.0:
				_handle_tap(event.position)
			_is_drag = false
		return
	if event is InputEventScreenDrag:
		if _touch_start.distance_to(event.position) > 10.0:
			_is_drag = true
		return  # deixa CameraRig lidar com pan
	# Mouse para debug PC
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tap(event.position)
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_request_end_turn()
		elif event.keycode == KEY_J:
			get_tree().change_scene_to_file("res://content/maps/journey_map.tscn")
