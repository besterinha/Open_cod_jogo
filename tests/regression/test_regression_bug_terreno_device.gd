extends GutTest
# Regression: obstáculos devem existir MESMO se .tscn ext_resource e load(.tres)
# falharem dentro do PCK exportado (bug device: tabuleiro sem muro nenhum).
# Nível 3 = layout embutido em código (script sempre viaja no pacote).


func test_fallback_const_valida_contra_schema() -> void:
	var l := TacticalArena.make_fallback_layout()
	assert_eq(l.size, Vector2i(8, 8))
	var errs: Array[String] = BoardLayoutResource.validate(l)
	assert_eq(errs.size(), 0, "layout embutido deve validar limpo: %s" % [errs])


func test_fallback_tem_muros_espinho_e_custo() -> void:
	var l := TacticalArena.make_fallback_layout()
	assert_true(l.is_blocked(Vector2i(2, 1)), "muro em (2,1)")
	assert_true(l.is_blocked(Vector2i(3, 1)), "muro em (3,1)")
	assert_true(l.is_blocked(Vector2i(3, 2)), "muro em (3,2)")
	assert_true(l.is_damage_floor(Vector2i(4, 4)), "espinho em (4,4)")
	assert_eq(l.move_cost(Vector2i(3, 5)), 4, "custo 4 na zona '44'")
	assert_eq(l.move_cost(Vector2i(6, 2)), 3, "custo 3 na zona '3'")


func test_resolve_cadeia_l1_l2_l3() -> void:
	var arena_script: GDScript = load("res://content/maps/tactical_arena.gd")
	var inst: Node3D = (arena_script as GDScript).new() as Node3D
	# L1: node já traz layout válido → preserva
	var l_ok := BoardLayoutResource.new()
	l_ok.size = Vector2i(2, 2)
	l_ok.rows = PackedStringArray([".#", ".."])
	var out1: BoardLayoutResource = inst._resolve_layout(l_ok, null)
	assert_same(out1, l_ok, "L1 preserva layout do node")
	assert_eq(inst.terrain_level, "L1")
	# L2: load devolveu .tres válido → usa
	var tres_like: BoardLayoutResource = TacticalArena.make_fallback_layout()
	var out2: BoardLayoutResource = inst._resolve_layout(null, tres_like)
	assert_same(out2, tres_like, "L2 usa resource carregado")
	assert_eq(inst.terrain_level, "L2")
	# L3: tudo falhou → const embutida com obstáculos garantidos
	var out3: BoardLayoutResource = inst._resolve_layout(null, null)
	assert_not_null(out3, "L3 nunca pode ser null")
	assert_true(out3.is_blocked(Vector2i(2, 1)), "L3 mantém muro")
	assert_eq(inst.terrain_level, "L3")
	inst.free()


func test_cena_real_sem_terreno_node_ainda_bloqueia_muro() -> void:
	# pior caso device: TerrainLayer ausente/genérico → _ready recria em código
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node("TacticalBoard")
	assert_not_null(board.terrain, "board.terrain sempre wireado")
	if board.terrain == null:
		return
	assert_false(board.is_walkable(Vector2i(2, 1)), "consumidor Board bloqueia muro")
