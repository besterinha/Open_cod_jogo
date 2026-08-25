extends Node
# Bootstrap do self-test de pacote (TDD §4e): binário exportado com "--selftest"
# redireciona para a cena SelfTest em vez da jornada. No-op no jogo normal.


func _ready() -> void:
	if OS.get_cmdline_user_args().has("--selftest"):
		print("[SelfTest] flag detectada — redirecionando para cena selftest")
		get_tree().change_scene_to_file.call_deferred("res://content/selftest/selftest.tscn")
