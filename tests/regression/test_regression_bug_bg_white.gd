extends GutTest
# Regression: fundo branco — env mode 1 (custom color) + clear_color branco no projeto
# Bug device: background_mode=0 (Clear Color) ignorava background_color e mostrava cinza 0.156


func test_default_clear_color_branco() -> void:
	var c: Color = ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color")
	assert_eq(c, Color(1, 1, 1, 1), "default_clear_color deve ser branco puro (fundo sem env)")


func test_env_background_custom_color_branco() -> void:
	var env: Environment = load("res://default_env.tres") as Environment
	assert_not_null(env)
	assert_eq(
		env.background_mode,
		Environment.BG_COLOR,
		"background_mode deve ser BG_COLOR (1) para aplicar background_color"
	)
	assert_eq(env.background_color, Color(1, 1, 1, 1), "background_color branco puro")
	assert_eq(env.ambient_light_color, Color(1, 1, 1, 1))
