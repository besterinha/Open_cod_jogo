extends GutTest
# Regression: elo arquivo→cena — a arena real deve carregar o layout de
# data/maps/tactical_arena.tres pelo .tscn e o board respeitar o muro (bug device pós-T1)


func test_cena_real_wire_terreno_do_arquivo() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node_or_null("TacticalBoard") as TacticalBoard
	assert_not_null(board)
	# ASSERT no consumidor (board): terreno veio do ARQUIVO via cena, não de injeção de teste
	assert_not_null(
		board.terrain, "board.terrain deve ser wireado pelo _ready a partir do .tscn/.tres"
	)
	if board.terrain == null:
		return
	var wall := Vector2i(2, 1)  # muro do layout demo ("..##...." linha 1)
	assert_true(board.terrain.is_blocked(wall), "muro (2,1) do arquivo deve estar ativo")
	assert_false(board.is_walkable(wall), "consumidor Board não deve permitir andar no muro")
	# dano de piso do arquivo
	assert_true(board.terrain.layout.is_damage_floor(Vector2i(4, 4)), "^ em (4,4)")
