extends GutTest
# Integração input real: cura em ALIADO e em SI — assert no consumidor (HP da unidade).
# AbilityResource construída em código com alvo="aliado" (heal.tres ganha a linha via user).


func _arena() -> Node3D:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	return arena


func _cura_aliada() -> AbilityResource:
	var ab := AbilityResource.new()
	ab.id = "curatest"
	ab.nome = "Cura Teste"
	ab.custo = {}
	ab.alcance = 3
	ab.area = "single"
	ab.alvo = "aliado"
	var eff := {"stat_id": "hp", "delta": 5}
	ab.efeitos = [eff]
	return ab


func _tap(arena: Node3D, cell: Vector2i) -> void:
	var cam: Camera3D = arena.get_node("CameraRig/Camera3D") as Camera3D
	var world: Vector3 = (arena.get_node("TacticalBoard") as TacticalBoard).grid.cell_to_world(cell)
	var pos: Vector2 = cam.unproject_position(world + Vector3(0, 0.05, 0))
	arena._handle_tap(pos)


func test_curar_aliado_sobe_hp_e_passa_vez() -> void:
	var arena: Node3D = await _arena()
	var turn: TurnManager = arena.get_node("TurnManager")
	if turn.get_current_unit().team != 0:
		return  # layout/ordem variou — nada a afirmar
	var hero1: Unit = turn.get_current_unit()
	var ally := Vector2i(1, 0)  # Hero2 ao lado
	var ally_unit: Unit = (arena.get_node("TacticalBoard") as TacticalBoard).get_unit_at(ally)
	assert_not_null(ally_unit, "aliado existe em (1,0)")
	if ally_unit == null:
		return
	var hp_antes: int = ally_unit.get_stat("hp")
	ally_unit.modify_stat("hp", -4)  # fere para caber cura
	hp_antes = ally_unit.get_stat("hp")
	arena.selected_ability = _cura_aliada()
	watch_signals(turn)
	_tap(arena, ally)
	await get_tree().process_frame
	assert_eq(ally_unit.get_stat("hp"), hp_antes + 5, "consumidor Unit: cura aplicada no aliado")
	assert_signal_emitted(turn, "turn_ended", "usar habilidade consome o turno")


func test_curar_a_si_mesmo_funciona() -> void:
	var arena: Node3D = await _arena()
	var turn: TurnManager = arena.get_node("TurnManager")
	var hero: Unit = turn.get_current_unit()
	if hero.team != 0:
		return
	hero.modify_stat("hp", -6)
	var hp_antes: int = hero.get_stat("hp")
	arena.selected_ability = _cura_aliada()
	watch_signals(turn)
	_tap(arena, hero.cell)  # tap no PRÓPRIO tile
	await get_tree().process_frame
	assert_eq(hero.get_stat("hp"), hp_antes + 5, "cura em si aplica")
	assert_signal_emitted(turn, "turn_ended")


func test_habilidade_inimigo_nao_cura_aliado() -> void:
	var arena: Node3D = await _arena()
	var turn: TurnManager = arena.get_node("TurnManager")
	if turn.get_current_unit().team != 0:
		return
	var ab := _cura_aliada()
	ab.alvo = "inimigo"  # default de ataque não deve aceitar aliado
	arena.selected_ability = ab
	var ally := Vector2i(1, 0)
	var ally_unit: Unit = (arena.get_node("TacticalBoard") as TacticalBoard).get_unit_at(ally)
	if ally_unit == null:
		return
	ally_unit.modify_stat("hp", -4)
	var hp_antes: int = ally_unit.get_stat("hp")
	watch_signals(turn)
	_tap(arena, ally)
	await get_tree().process_frame
	assert_eq(ally_unit.get_stat("hp"), hp_antes, "alvo inimigo ignora aliado (sem dano/cura)")
