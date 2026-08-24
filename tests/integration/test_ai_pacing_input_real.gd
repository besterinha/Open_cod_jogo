extends GutTest
# Regression: IA sequencial — quando o turno do próximo inimigo começa,
# o inimigo anterior já terminou de andar (is_moving false). Bug device pós-T2.


func test_proximo_inimigo_so_anda_apois_anterior_parar() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var board: TacticalBoard = arena.get_node("TacticalBoard")
	var turn: TurnManager = arena.get_node("TurnManager")
	var movement: MovementSystem = arena.get_node("MovementSystem")
	# passa a vez até um inimigo (team 1) assumir — IA joga sozinha
	for i in 6:
		if turn.get_current_unit() != null and turn.get_current_unit().team == 1:
			break
		var hud: Control = arena.get_node("CanvasLayer/TacticalHUD")
		(hud.get_node("HBox/EndTurn") as Button).pressed.emit()
		await get_tree().create_timer(0.15).timeout
	var e1: Unit = turn.get_current_unit()
	assert_not_null(e1)
	if e1 == null or e1.team != 1:
		return  # layout impediu chegar a team1 — nada a afirmar
	# espera IA do e1 concluir o próprio turno (mover+agir+end_turn com pacing)
	await get_tree().create_timer(0.4).timeout
	var moved := false
	while turn.get_current_unit() == e1:
		if movement.is_moving(e1):
			moved = true
		await get_tree().process_frame
	if moved:
		print("[Test] e1 moveu antes do end_turn — pacing exercitado")
	# momento em que e1 deixou de ser a vez: transição para próxima unidade
	var t_transition := Time.get_ticks_msec()
	while movement.is_moving(e1):
		# regra: NENHUM novo turno pode iniciar enquanto e1 ainda anima
		assert_same(
			turn.get_current_unit(),
			e1,
			"end_turn não deve ocorrer antes da animação da IA terminar"
		)
		await get_tree().process_frame
		if Time.get_ticks_msec() - t_transition > 6000:
			break  # salvaguarda
	var e2: Unit = turn.get_current_unit()
	assert_not_same(e2, e1, "próximo turno chegou")
	assert_false(
		movement.is_moving(e1),
		"inimigo anterior parou antes do próximo assumir (consumidor Movement)"
	)
