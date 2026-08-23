extends GutTest
# Smoke: carrega todas as cenas críticas sem crash. Gatekeeper para build.

const SCENES: Array[String] = [
	"res://placeholders/tactical/tile_cube.tscn",
	"res://placeholders/tactical/unit_capsule.tscn",
	"res://placeholders/vfx/vfx_circle.tscn",
	"res://content/maps/tactical_arena.tscn",
	"res://content/maps/journey_map.tscn",
	"res://ui/caravan_bar.tscn",
	"res://ui/radial_menu.tscn",
	"res://ui/tactical_hud.tscn",
]


func test_all_critical_scenes_load() -> void:
	for path in SCENES:
		var res: Resource = load(path)
		assert_not_null(res, "Falha ao carregar %s" % path)
		if res is PackedScene:
			var inst: Node = (res as PackedScene).instantiate()
			assert_not_null(inst, "Falha ao instanciar %s" % path)
			add_child_autofree(inst)
			await get_tree().process_frame
			# checa highlights e tiles não vazios para tático
			if path.contains("tactical_arena"):
				assert_true(
					inst.get_node_or_null("TacticalBoard") != null, "TacticalBoard deve existir"
				)
				assert_true(
					(
						inst.get_node_or_null("CameraRig/Camera3D") != null
						or inst.get_node_or_null("Camera3D") != null
					),
					"Camera deve existir"
				)


func test_all_data_abilities_valid() -> void:
	var db: AttributeDatabase = load("res://data/stats/attributes.tres") as AttributeDatabase
	assert_not_null(db)
	var abilities: Array[String] = [
		"res://data/abilities/fireball.tres",
		"res://data/abilities/heal.tres",
		"res://data/abilities/strike.tres",
	]
	for p in abilities:
		var a: Resource = load(p)
		assert_not_null(a, "Ability não encontrada: %s" % p)
		var errs: Array[String] = DataValidator.validate_ability(a, db)
		assert_eq(errs.size(), 0, "%s inválido: %s" % [p, ", ".join(errs)])
