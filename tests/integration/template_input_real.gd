extends GutTest
# TEMPLATE input real — assert no CONSUMIDOR downstream (não no emissor)
# Copie este arquivo para tests/integration/test_<sua_mecanica>_input_real.gd
# Boundary: emissor (ex: Input) -> consumidor (ex: Board/Combat/Turn/EventBus)
# Regra: act via InputEventScreenTouch / arena._handle_tap / botão HUD real,
# não via emissor.funcao_direta. Assert deve estar no consumidor que lê o efeito.
#
# Exemplo estrutura (sem func test_ aqui — não conta na pirâmide):
#   var arena: Node3D = preload("res://content/maps/tactical_arena.tscn").instantiate()
#   add_child_autofree(arena)
#   await get_tree().process_frame
#   var board: TacticalBoard = arena.get_node("TacticalBoard")
#   var combat: CombatManager = arena.get_node("CombatManager")
#   var turn: TurnManager = arena.get_node("TurnManager")
#   var unit: Unit = turn.get_current_unit()
#   watch_signals(combat) # consumidor
#   var cam: Camera3D = arena.get_node("CameraRig/Camera3D")
#   var screen_pos: Vector2 = cam.unproject_position(board.grid.cell_to_world(target))
#   arena.call("_handle_tap", screen_pos) # input real via handler
#   await get_tree().process_frame
#   assert_signal_not_emitted(combat, "ability_used") # se era move
#   assert_eq(board.get_unit_at(target), unit) # consumidor Board
