extends GutTest
# T2 Áreas Strategy: registry, cone/ring determinísticos, compat legado, validator custom


func _grid() -> GridSystem:
	return GridSystem.new(Vector2i(9, 9), 1.0)


func test_registry_builtins_e_fallback() -> void:
	for id in ["single", "3x3", "cross", "line", "cone", "ring"]:
		assert_not_null(AreaShapeRegistry.shape_for(id), "shape %s registrado" % id)
	var cells: Array[Vector2i] = AreaShapeRegistry.cells_for(
		"banana", Vector2i.ZERO, Vector2i(5, 5), _grid()
	)
	assert_eq(cells, [Vector2i(5, 5)], "id desconhecido cai em single (fallback seguro)")


func test_legado_3x3_cross_line_iguais_antes() -> void:
	var g := _grid()
	var o := Vector2i(4, 4)
	var t33: Array[Vector2i] = AreaShapeRegistry.cells_for("3x3", o, o, g)
	assert_eq(t33.size(), 9, "3x3 continua 9 células")
	assert_true(t33.has(o + Vector2i(-1, -1)) and t33.has(o + Vector2i(1, 1)))
	var tcross: Array[Vector2i] = AreaShapeRegistry.cells_for("cross", o, o, g)
	assert_eq(tcross.size(), 5, "cross continua 5")
	assert_true(tcross.has(o + Vector2i(0, -1)))
	var tline: Array[Vector2i] = AreaShapeRegistry.cells_for("line", o, o, g)
	assert_eq(tline, [o, o + Vector2i(1, 0), o + Vector2i(2, 0)], "line legado +x")


func test_cone_abre_na_direcao_do_alvo() -> void:
	var g := _grid()
	var cone := AreaShapeRegistry.shape_for("cone") as AreaShapeCone
	cone.length = 3
	var origin := Vector2i(2, 2)
	# alvo à direita: frente +x, abre perpendicular (y)
	var cells: Array[Vector2i] = cone.get_cells(origin, Vector2i(6, 2), g)
	assert_true(cells.has(origin), "cone inclui origem (passo 0)")
	assert_true(cells.has(Vector2i(4, 2)), "frente no passo 2")
	assert_true(cells.has(Vector2i(3, 1)) and cells.has(Vector2i(3, 3)), "abre lateral no passo 1")
	assert_true(cells.has(Vector2i(4, 0)) and cells.has(Vector2i(4, 4)), "largura 5 no passo 2")
	assert_false(cells.has(Vector2i(2, 5)), "não vai atrás da origem")
	# alvo abaixo: frente rotaciona para +y
	var down: Array[Vector2i] = cone.get_cells(origin, Vector2i(2, 7), g)
	assert_true(down.has(Vector2i(2, 4)), "frente vira +y")
	assert_true(down.has(Vector2i(1, 3)) and down.has(Vector2i(3, 3)), "lateral em x")


func test_ring_raio_exato_com_buraco() -> void:
	var g := _grid()
	var ring := AreaShapeRegistry.shape_for("ring") as AreaShapeRing
	ring.radius = 2
	var target := Vector2i(4, 4)
	var cells: Array[Vector2i] = ring.get_cells(Vector2i.ZERO, target, g)
	assert_false(cells.has(target), "anel tem buraco no centro")
	assert_true(cells.has(target + Vector2i(2, 0)) and cells.has(target + Vector2i(0, 2)))
	assert_true(cells.has(target + Vector2i(1, 1)), "manhattan==raio inclui diagonais curtas")
	assert_false(cells.has(target + Vector2i(1, 0)), "distância 1 não entra no anel r=2")
	for c in cells:
		assert_true(g.is_within_bounds(c))


func test_ability_area_shape_sobrepoe_string() -> void:
	var abil := AbilityResource.new()
	abil.id = "teste_shape"
	abil.nome = "Cone Teste"
	abil.area = "single"  # string legada dizeria single...
	abil.area_shape = AreaShapeRing.new()
	abil.area_shape.radius = 1
	var cells: Array[Vector2i] = abil.resolve_area_cells(Vector2i.ZERO, Vector2i(5, 5), _grid())
	assert_eq(cells.size(), 4, "area_shape vence a string: ring r=1 tem 4 células")
	assert_false(cells.has(Vector2i(5, 5)))


func test_validator_aceita_custom_e_rejeita_string_invalida() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	var ok := AbilityResource.new()
	ok.id = "cone_ok"
	ok.nome = "Cone OK"
	ok.custo = {"willpower": 1}
	ok.efeitos = [{"stat_id": "hp", "delta": -4}]
	ok.area_shape = AreaShapeCone.new()
	var errs: Array[String] = DataValidator.validate_ability(ok, db)
	assert_eq(errs.size(), 0, "custom shape válido: %s" % ", ".join(errs))
	var bad := AbilityResource.new()
	bad.id = "bad_area"
	bad.nome = "Bad"
	bad.custo = {"willpower": 1}
	bad.efeitos = [{"stat_id": "hp", "delta": -1}]
	bad.area = "estrela"
	errs = DataValidator.validate_ability(bad, db)
	assert_true(errs.size() >= 1, "string fora da whitelist sem shape segue reprovando")


func test_tres_demos_carregam_e_validam() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	for path in [
		"res://data/abilities/conejato.tres",
		"res://data/abilities/anelado.tres",
	]:
		var a: Resource = load(path) as Resource
		assert_not_null(a, path + " carrega")
		var errs: Array[String] = DataValidator.validate_ability(a as AbilityResource, db)
		assert_eq(errs.size(), 0, "%s válido: %s" % [path, ", ".join(errs)])
	var cone: AbilityResource = load("res://data/abilities/conejato.tres")
	assert_not_null(cone.area_shape, "conejato tem area_shape plugada")
	assert_eq(cone.area_shape.shape_id(), "cone")
