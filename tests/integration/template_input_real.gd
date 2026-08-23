extends GutTest
# TEMPLATE input real — assert no CONSUMIDOR downstream (não no emissor)
# Copie este arquivo para tests/integration/test_<sua_mecanica>_input_real.gd
# Boundary: emissor (ex: Input) -> consumidor (ex: Board/Combat/Turn/EventBus)
# Regra: act via InputEventScreenTouch / arena._handle_tap / radial action real, não via emissor.funcao_direta
# Assert deve estar no consumidor que lê o efeito.

# Exemplo estrutura:
# func test_minha_mecanica_input_real() -> void:
#   var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate()
#   add_child_autofree(arena)
#   await get_tree().process_frame
#   var board: TacticalBoard = arena.get_node("TacticalBoard")
#   var combat: CombatManager = arena.get_node("CombatManager")
#   var turn: TurnManager = arena.get_node("TurnManager")
#   var unit: Unit = turn.get_current_unit()
#   var target: Vector2i = unit.cell + Vector2i(1,0)
#   watch_signals(combat) # consumidor
#   watch_signals(board)  # consumidor
#   # ACT input real (não unit.move_to ou combat.use_ability direto)
#   var cam: Camera3D = arena.get_node("CameraRig/Camera3D")
#   var screen_pos: Vector2 = cam.unproject_position(board.grid.cell_to_world(target))
#   arena.call("_handle_tap", screen_pos) # input real via handler
#   await get_tree().process_frame
#   # ASSERT no consumidor downstream:
#   assert_signal_not_emitted(combat, "ability_used") # se era move
#   assert_eq(board.get_unit_at(target), unit)
#   assert_eq(turn.get_current_unit(), unit) # ou mudou


func test_template_dummy_pass() -> void:
	assert_true(true, "template existe para copiar")
