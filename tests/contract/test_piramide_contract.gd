extends GutTest
# Contract C8: pirâmide — conta FUNÇÕES de teste reais (grep ^func test_), não arquivos
# Piso relativo com margem 5pp abaixo do real pós-PASSO1 (unit 45 46.9%, integration 25 26%, cse 26 27%)
# Falha visível se unit <40% ou integration <20% ou cse >35% — protege contra apagar 88% sem falhar


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


func _count_tests_in_dir(dir_path: String) -> int:
	var d := DirAccess.open(dir_path)
	if d == null:
		return 0
	d.list_dir_begin()
	var f: String = d.get_next()
	var total: int = 0
	while f != "":
		if f.ends_with(".gd"):
			var fa := FileAccess.open(dir_path + "/" + f, FileAccess.READ)
			if fa:
				var txt: String = fa.get_as_text()
				# conta "^func test_" por arquivo (grep em GDScript)
				var lines: PackedStringArray = txt.split("\n")
				for line in lines:
					if line.strip_edges().begins_with("func test_"):
						total += 1
		f = d.get_next()
	return total


func test_piramide_proporcao_funcoes_com_piso_relativo() -> void:
	var c_u: int = _count_tests_in_dir("res://tests/unit")
	var c_i: int = _count_tests_in_dir("res://tests/integration")
	var c_c: int = _count_tests_in_dir("res://tests/contract")
	var c_s: int = _count_tests_in_dir("res://tests/smoke")
	var c_e: int = _count_tests_in_dir("res://tests/e2e")
	var c_r: int = _count_tests_in_dir("res://tests/regression")
	var total: int = c_u + c_i + c_c + c_s + c_e + c_r
	assert_true(total >= 80, "total de func test_ deve ser >=80, tem " + str(total))
	var p_u: float = c_u * 100.0 / total
	var p_i: float = c_i * 100.0 / total
	var p_cse: float = (c_c + c_s + c_e + c_r) * 100.0 / total
	print(
		(
			"Piramide funcoes: unit %d (%.1f%%) integration %d (%.1f%%) cse %d (%.1f%%) total %d"
			% [c_u, p_u, c_i, p_i, c_c + c_s + c_e + c_r, p_cse, total]
		)
	)
	# piso relativo 5pp abaixo do real pós-PASSO1 (46.9/26/27) — falha visível se apagar 30% unit
	assert_true(
		p_u >= 40.0,
		"piramide unit <40%% (real 46.9%%), p_u=%.1f%% c_u=%d total=%d" % [p_u, c_u, total]
	)
	assert_true(p_i >= 20.0, "piramide integration <20%% (real 26%%), p_i=%.1f%%" % p_i)
	assert_true(p_cse <= 35.0, "piramide cse >35%% (real 27%%), p_cse=%.1f%%" % p_cse)
