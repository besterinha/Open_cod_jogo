extends GutTest
# Regression: botões do HUD não podem depender de listagem de diretório —
# dentro do APK res:// não tem pastas navegáveis (bug device pós-T2)


func test_hud_monta_botoes_sem_diraccess() -> void:
	var hud: Control = preload("res://ui/tactical_hud.tscn").instantiate() as Control
	add_child_autofree(hud)
	await get_tree().process_frame
	# consumidor real: botões criados a partir da lista export-safe BASE_ABILITY_PATHS
	var btns: Array[String] = []
	for c in hud.get_node("HBox").get_children():
		if c is Button and (c as Button).name != "EndTurn":
			btns.append(str((c as Button).name))
	assert_true(
		btns.has("strike") and btns.has("heal") and btns.has("fireball"),
		"3 habilidades base devem existir sem depender de glob"
	)
	assert_true(btns.has("conejato"), "conejato vem da lista export-safe")
	assert_true(btns.has("anelado"), "anelado vem da lista export-safe")


func test_lista_export_safe_cobre_todos_os_tres_de_data() -> void:
	# guarda de consistência: todo .tres em data/abilities deve estar na lista
	# (se este teste falhar ao adicionar habilidade nova, registre o path na lista)
	var hud_script: GDScript = load("res://ui/tactical_hud.gd")
	var lista: Array = (
		hud_script.get("BASE_ABILITY_PATHS") if "BASE_ABILITY_PATHS" in hud_script else []
	)
	assert_true(not lista.is_empty(), "BASE_ABILITY_PATHS deve existir no HUD")
	var dir := DirAccess.open("res://data/abilities/")
	if dir == null:
		return  # ambiente sem glob (não deveria ocorrer no editor)
	dir.list_dir_begin()
	var file: String = dir.get_next()
	while file != "":
		if file.ends_with(".tres"):
			var path: String = "res://data/abilities/" + file
			assert_true(
				lista.has(path), path + " existe em data/ mas não está na lista export-safe do HUD"
			)
		file = dir.get_next()
	dir.list_dir_end()
