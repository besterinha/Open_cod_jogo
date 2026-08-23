extends GutTest
# Integração Input -> Combat via _handle_tap raycast


func test_tap_em_inimigo_dispara_combate() -> void:
	# Teste isolado sem depender do arena default (que tem inimigos longe)
	var board := TacticalBoard.new()
	board.grid_size = Vector2i(5, 5)
	board.grid = GridSystem.new(Vector2i(5, 5), 1.0)
	add_child_autofree(board)
	var unit := Unit.new()
	unit.unit_id = "hero"
	unit.display_name = "Hero"
	unit.team = 0
	unit.cell = Vector2i(0, 0)
	unit.stats = UnitStats.new()
	unit.stats.set_stat("hp", 10)
	unit.stats.set_stat("willpower", 5)
	board.add_unit(unit)
	var enemy := Unit.new()
	enemy.unit_id = "enemy"
	enemy.display_name = "Enemy"
	enemy.team = 1
	enemy.cell = Vector2i(0, 1)  # ao lado, alcance 1
	enemy.stats = UnitStats.new()
	enemy.stats.set_stat("hp", 10)
	board.add_unit(enemy)
	var cm := CombatManager.new()
	cm.setup(board)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
	watch_signals(cm)
	var before_hp: int = enemy.get_stat("hp")
	var ok: bool = cm.use_ability(unit, abil, enemy.cell)
	assert_true(ok)
	assert_signal_emitted(cm, "damage_applied")
	assert_eq(enemy.get_stat("hp"), before_hp - 4)


func test_tap_fora_alcance_nao_consume() -> void:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(8, 8)
	b.grid = GridSystem.new(Vector2i(8, 8), 1.0)
	add_child_autofree(b)
	var atk := Unit.new()
	atk.unit_id = "atk"
	atk.display_name = "Atk"
	atk.team = 0
	atk.cell = Vector2i(0, 0)
	atk.stats = UnitStats.new()
	atk.stats.set_stat("hp", 10)
	atk.stats.set_stat("willpower", 5)
	atk.stats.set_stat("movement", 3)
	b.add_unit(atk)
	var def := Unit.new()
	def.unit_id = "def"
	def.display_name = "Def"
	def.team = 1
	def.cell = Vector2i(7, 7)
	def.stats = UnitStats.new()
	def.stats.set_stat("hp", 10)
	b.add_unit(def)
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource  # alc 1
	var before_wp: int = atk.get_stat("willpower")
	watch_signals(cm)
	var ok: bool = cm.use_ability(atk, abil, def.cell)  # longe
	assert_false(ok, "fora do alcance não deve usar")
	assert_signal_not_emitted(cm, "ability_used")
	assert_eq(atk.get_stat("willpower"), before_wp, "sem custo se falhou")
