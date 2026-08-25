extends GutTest
# Integração: ações do menu radial da jornada — assert no CONSUMIDOR (§7b):
# outcome observável + toast visível na árvore. Nenhum clique pode ficar silencioso.


func _journey() -> Node3D:
	var jm: Node3D = preload("res://content/maps/journey_map.tscn").instantiate() as Node3D
	add_child_autofree(jm)
	await get_tree().process_frame
	await get_tree().process_frame
	return jm


func test_todas_acoes_radiais_geram_outcome_e_toast() -> void:
	var jm: Node3D = await _journey()
	for action in ["viajar", "descansar", "mercado", "evento"]:
		jm._on_radial_action(action)
		assert_false(
			(jm.last_action_outcome as String).is_empty(), "ação %s deve registrar outcome" % action
		)
		var layer: CanvasLayer = jm.get_node("CanvasLayer")
		var found := false
		for c in layer.get_children():
			if c is Label and (c as Label).text.length() > 0 and c.name != "HelpLabel":
				found = true
		assert_true(found, "ação %s deve gerar feedback visível (toast)" % action)
	# ação desconhecida também não é silenciosa
	jm._on_radial_action("inexistente")
	assert_eq(jm.last_action_outcome, "unknown:inexistente")


func test_batalha_radial_emite_eventbus_sem_trocar_cena_de_teste() -> void:
	var jm: Node3D = await _journey()
	watch_signals(EventBus)
	jm._on_radial_action("batalha")
	assert_signal_emitted(EventBus, "battle_requested")
	assert_eq(jm.last_action_outcome, "battle_requested")
	# guarda anti-troca: cena do runner NÃO pode ser substituída fora do jogo real
	assert_ne(get_tree().current_scene, jm, "journey instanciada em teste não é current_scene")


func test_botoes_radiais_existem_na_cena() -> void:
	var jm: Node3D = await _journey()
	var radial: Control = jm.get_node("CanvasLayer/RadialMenu") as Control
	var names := ["viajar", "descansar", "mercado", "evento", "batalha"]
	for n in names:
		assert_not_null(radial.find_child(n, true, false), "botão radial %s existe" % n)
