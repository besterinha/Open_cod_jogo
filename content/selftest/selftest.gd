extends Node
# Self-test do PACOTE EXPORTADO (TDD §4e): roda dentro do binário exportado
# via flag "--selftest". Verifica que terreno/habilidades/HUD existem NO PCK,
# imprime marcador e sai com código. CI/local: bash ci/export-selftest.sh
# PASS=exit 0, FAIL=exit 1.

const ARENA_SCENE := "res://content/maps/tactical_arena.tscn"


func _ran_from_scene() -> bool:
	return get_tree().current_scene == self


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--selftest") and not _ran_from_scene():
		# cena carregada sem a flag (ex: dev rodando direto) — executa mesmo assim
		print("[SelfTest] aviso: sem --selftest na cmdline; executando mesmo assim")
	await get_tree().process_frame
	await get_tree().process_frame
	var fails: Array[String] = []
	var arena: Node3D = load(ARENA_SCENE).instantiate() as Node3D
	add_child(arena)
	await get_tree().process_frame
	await get_tree().process_frame

	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	if board == null:
		fails.append("TacticalBoard ausente")
	elif board.terrain == null:
		fails.append("board.terrain null — terreno NÃO carregou do pacote")
	else:
		if not board.terrain.is_blocked(Vector2i(2, 1)):
			fails.append("muro (2,1) não bloqueia")
		var walls := 0
		for x in 8:
			for y in 8:
				if board.terrain.is_blocked(Vector2i(x, y)):
					walls += 1
		if walls < 3:
			fails.append("poucos muros: %d" % walls)
		print("[SelfTest] terreno nivel=%s muros=%d" % [arena.terrain_level, walls])

	var dark := 0
	var tiles: Node = board.get_node_or_null("Tiles")
	if tiles != null:
		for t in tiles.get_children():
			var m: MeshInstance3D = t as MeshInstance3D
			if m != null and m.material_override != null:
				var mat: StandardMaterial3D = m.material_override as StandardMaterial3D
				if mat != null and mat.albedo_color.r < 0.5:
					dark += 1
	print("[SelfTest] tiles_escuros=%d" % dark)
	if dark < 3:
		fails.append("tiles de muro sem tint escuro: %d" % dark)

	var hud: Control = arena.get_node_or_null("CanvasLayer/TacticalHUD") as Control
	var btn_count := 0
	if hud == null:
		fails.append("HUD ausente")
	elif not hud.has_method("get_loaded_count"):
		fails.append("HUD sem get_loaded_count")
	else:
		btn_count = hud.get_loaded_count()
		print("[SelfTest] abilities=%d" % btn_count)
		if btn_count < 5:
			fails.append("habilidades carregadas no pacote: %d (<5)" % btn_count)
		# guarda do design data-driven: .tres precisa manter CONTEÚDO no pacote
		var fb: Resource = load("res://data/abilities/fireball.tres")
		if fb is AbilityResource:
			var ab := fb as AbilityResource
			print("[SelfTest] fireball custo=%s area=%s" % [ab.custo, ab.area])
			if ab.custo.is_empty():
				fails.append("fireball.tres perdeu custo no empacotamento!")
			if ab.efeitos.is_empty():
				fails.append("fireball.tres perdeu efeitos no empacotamento!")
		else:
			fails.append("fireball.tres não carrega como AbilityResource")

	var diag: Label = arena.get_node_or_null("CanvasLayer/DiagLabel") as Label
	if diag == null or diag.text.is_empty():
		fails.append("DiagLabel ausente/vazia")
	else:
		print("[SelfTest] diag='%s'" % diag.text)

	# sonda raiz: o que o pacote entrega ao load() do .tres do mapa?
	var probe: Resource = load("res://data/maps/tactical_arena.tres")
	if probe == null:
		print("[SelfTest] probe_mapa=null (arquivo não carrega)")
	else:
		var p_rows = probe.get("rows")
		print(
			(
				"[SelfTest] probe_mapa tipo=%s classe=%s rows=%s"
				% [probe.get_class(), probe.get_script(), str(p_rows).left(40)]
			)
		)

	arena.queue_free()
	if fails.is_empty():
		print("[SelfTest] PASS")
		get_tree().quit(0)
	else:
		for f in fails:
			push_error("[SelfTest] FAIL: " + f)
		print("[SelfTest] FAIL: %s" % [fails])
		get_tree().quit(1)
