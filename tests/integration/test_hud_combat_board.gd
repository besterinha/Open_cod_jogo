extends GutTest
# Integração: HUD + Combat + Board + Stats — pega HUD 0 vs lógica 3 e VFX sem dano

func _make_board() -> TacticalBoard:
	var b := TacticalBoard.new()
	b.grid_size = Vector2i(5, 5)
	b.grid = GridSystem.new(Vector2i(5, 5), 1.0)
	add_child_autofree(b)
	return b

func _make_unit(id: String, team: int, cell: Vector2i, hp: int = 10) -> Unit:
	var u := Unit.new()
	u.unit_id = id
	u.display_name = id
	u.team = team
	u.cell = cell
	u.stats = UnitStats.new()
	u.stats.set_stat("hp", hp)
	u.stats.set_stat("willpower", 5)
	u.stats.set_stat("movement", 3)
	return u

func test_hud_and_logic_agree_on_cost() -> void:
	# HUD deve desabilitar se lógica não pode pagar
	var b := _make_board()
	var atk := _make_unit("atk", 0, Vector2i(0,0))
	atk.stats.set_stat("willpower", 1) # só 1
	b.add_unit(atk)
	var abil: AbilityResource = load("res://data/abilities/fireball.tres") as AbilityResource # custa 2
	assert_false(atk.can_pay(abil.custo), "lógica: não pode pagar 2 com 1")
	# HUD simula disabled
	var hud := preload("res://ui/tactical_hud.tscn").instantiate() as Control
	add_child_autofree(hud)
	await get_tree().process_frame
	# força atualizar com unidade atual
	if hud.has_method("_on_turn_changed"):
		hud.call("_on_turn_changed", atk)
	await get_tree().process_frame
	# checa botão fireball desabilitado
	var fire_btn: Button = hud.get_node_or_null("HBox/fireball") as Button
	if fire_btn:
		assert_true(fire_btn.disabled, "HUD fireball deve ficar disabled sem willpower")

func test_vfx_and_damage_atomicos() -> void:
	var b := _make_board()
	var atk := _make_unit("atk", 0, Vector2i(0,0))
	var def := _make_unit("def", 1, Vector2i(1,0), 10)
	b.add_unit(atk)
	b.add_unit(def)
	var cm := CombatManager.new()
	var resolver: CombatResolver = load("res://systems/tactical/combat/resolvers/resolver_default.gd").new()
	cm.setup(b, resolver)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/strike.tres") as AbilityResource
	# vigia sinais
	watch_signals(cm)
	var ok: bool = cm.use_ability(atk, abil, def.cell)
	assert_true(ok, "deve conseguir usar strike")
	assert_signal_emitted(cm, "ability_used")
	assert_signal_emitted(cm, "damage_applied")
	assert_eq(def.get_stat("hp"), 6, "strike -4 em 10 => 6 (hp_only)")

func test_vfx_sem_dano_deve_falhar() -> void:
	# Tap em chão vazio com fireball 3x3 deve dar VFX e dano se inimigo na área, mas se área vazia, sem VFX e sem dano
	var b := _make_board()
	var atk := _make_unit("atk", 0, Vector2i(0,0))
	b.add_unit(atk)
	# sem inimigos na área
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/fireball.tres") as AbilityResource
	watch_signals(cm)
	var ok: bool = cm.use_ability(atk, abil, Vector2i(2,2)) # chão vazio, sem alvo
	# VFX emitida (ability_used) mas damage_applied não deve ter sido emitido (nenhum alvo)
	assert_true(ok, "fireball em chão vazio deve pagar custo e emitir ability_used")
	assert_signal_emitted(cm, "ability_used")
	assert_signal_not_emitted(cm, "damage_applied")

func test_fireball_area_acerta_vizinho() -> void:
	var b := _make_board()
	var atk := _make_unit("atk", 0, Vector2i(0,0))
	var def := _make_unit("def", 1, Vector2i(2,2), 10)
	b.add_unit(atk)
	b.add_unit(def)
	var cm := CombatManager.new()
	var resolver: CombatResolver = load("res://systems/tactical/combat/resolvers/resolver_default.gd").new()
	cm.setup(b, resolver)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/fireball.tres") as AbilityResource # 3x3, alc 5
	# mira em (1,1) vazio mas área pega (2,2)
	var target: Vector2i = Vector2i(1, 1)
	watch_signals(cm)
	var ok: bool = cm.use_ability(atk, abil, target)
	assert_true(ok, "fireball em (1,1) deve alcançar (2,2) via 3x3")
	assert_signal_emitted(cm, "damage_applied")
	assert_eq(def.get_stat("hp"), 4, "fireball -6 em 10 => 4")

func test_heal_cura_aliado() -> void:
	var b := _make_board()
	var healer := _make_unit("healer", 0, Vector2i(0,0))
	healer.stats.set_stat("willpower", 5)
	var ally := _make_unit("ally", 0, Vector2i(1,0), 5)
	b.add_unit(healer)
	b.add_unit(ally)
	var cm := CombatManager.new()
	cm.setup(b)
	add_child_autofree(cm)
	var abil: AbilityResource = load("res://data/abilities/heal.tres") as AbilityResource # +5 hp, alc 3
	watch_signals(cm)
	var ok: bool = cm.use_ability(healer, abil, ally.cell)
	assert_true(ok)
	assert_eq(ally.get_stat("hp"), 10, "heal +5 em 5 => 10")
	assert_signal_emitted(cm, "damage_applied")
