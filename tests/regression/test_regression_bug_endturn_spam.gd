extends GutTest
# Regression endturn_spam: Passar Turno só funciona na vez do jogador.
# Spam na vez da IA NÃO avança turno, não pula inimigo, mostra toast.


func _arena() -> Node3D:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	return arena


func _ate_vez_inimigo(arena: Node3D) -> Unit:
	var turn: TurnManager = arena.get_node("TurnManager")
	for i in 6:
		var u: Unit = turn.get_current_unit()
		if u != null and u.team == 1:
			return u
		arena._request_end_turn()
		await get_tree().create_timer(0.1).timeout
	return null


func test_spam_passar_vez_na_ia_nao_avanca() -> void:
	var arena: Node3D = await _arena()
	var enemy: Unit = await _ate_vez_inimigo(arena)
	assert_not_null(enemy, "deve chegar à vez de um inimigo")
	if enemy == null:
		return
	var turn: TurnManager = arena.get_node("TurnManager")
	assert_same(turn.get_current_unit(), enemy)
	# spam de apertos durante a vez da IA
	for i in 5:
		arena._request_end_turn()
	assert_same(
		turn.get_current_unit(), enemy, "spam na vez da IA não pode avançar turno (guarda team)"
	)


func test_jogador_pode_passar_propria_vez() -> void:
	var arena: Node3D = await _arena()
	var turn: TurnManager = arena.get_node("TurnManager")
	var hero: Unit = turn.get_current_unit()
	if hero == null or hero.team != 0:
		for i in 6:
			arena._request_end_turn()
			await get_tree().create_timer(0.15).timeout
			hero = turn.get_current_unit()
			if hero != null and hero.team == 0:
				break
	assert_not_null(hero)
	if hero == null or hero.team != 0:
		return
	watch_signals(turn)
	arena._request_end_turn()
	assert_signal_emitted(turn, "turn_ended", "jogador passa a própria vez normalmente")


func test_end_turn_bloqueia_durante_movimento() -> void:
	var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate() as Node3D
	add_child_autofree(arena)
	await get_tree().process_frame
	await get_tree().process_frame
	var turn: TurnManager = arena.get_node("TurnManager")
	var movement: MovementSystem = arena.get_node("MovementSystem")
	var hero: Unit = turn.get_current_unit()
	assert_not_null(hero)
	if hero == null or hero.team != 0:
		return
	movement.move_unit(hero, Vector2i(hero.cell.x + 1, hero.cell.y))
	if movement.is_moving(hero):
		watch_signals(turn)
		arena._request_end_turn()
		assert_signal_not_emitted(turn, "turn_ended", "passar vez com unidade animando é bloqueado")
