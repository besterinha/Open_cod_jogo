extends GutTest
# Contract C8: pirâmide 70/25/5 alvo + regression obrigatória
# Não bloqueia 100% exato, mas falha visível se regression faltar ou unit <30%


func test_regression_existe() -> void:
	var dir := DirAccess.open("res://tests/regression")
	assert_not_null(dir, "tests/regression deve existir")
	dir.list_dir_begin()
	var file: String = dir.get_next()
	var count: int = 0
	while file != "":
		if file.begins_with("test_regression_bug_") and file.ends_with(".gd"):
			count += 1
		file = dir.get_next()
	assert_true(
		count >= 2,
		"deve ter pelo menos 2 regression (grid 323542, pinch 983ab3b), tem " + str(count)
	)


func test_piramide_tem_unit_e_integration() -> void:
	var d_u := DirAccess.open("res://tests/unit")
	var c_u: int = 0
	if d_u:
		d_u.list_dir_begin()
		var f: String = d_u.get_next()
		while f != "":
			if f.ends_with(".gd"):
				c_u += 1
			f = d_u.get_next()
	var d_i := DirAccess.open("res://tests/integration")
	var c_i: int = 0
	if d_i:
		d_i.list_dir_begin()
		var f2: String = d_i.get_next()
		while f2 != "":
			if f2.ends_with(".gd"):
				c_i += 1
			f2 = d_i.get_next()
	assert_true(c_u >= 5, "unit deve ter >=5 arquivos (70% alvo), tem " + str(c_u))
	assert_true(c_i >= 4, "integration deve ter >=4 arquivos (25% alvo), tem " + str(c_i))
