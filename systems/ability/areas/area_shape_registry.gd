class_name AreaShapeRegistry
extends RefCounted
# Registro de formas de área por id — built-ins T2 + lookup p/ strings legadas.
# Nova forma built-in = adicionar aqui; forma custom = AbilityResource.area_shape (.tres).

const BUILTINS: Dictionary = {
	"single": "res://systems/ability/areas/shape_single.gd",
	"3x3": "res://systems/ability/areas/shape_3x3.gd",
	"cross": "res://systems/ability/areas/shape_cross.gd",
	"line": "res://systems/ability/areas/shape_line.gd",
	"cone": "res://systems/ability/areas/shape_cone.gd",
	"ring": "res://systems/ability/areas/shape_ring.gd",
}

static var _cache: Dictionary = {}


static func shape_for(id: String) -> AreaShape:
	if _cache.has(id):
		return _cache[id] as AreaShape
	var path: String = BUILTINS.get(id, "")
	if path == "" or not ResourceLoader.exists(path):
		return null
	var script: GDScript = load(path)
	var inst: AreaShape = script.new() as AreaShape
	_cache[id] = inst
	return inst


static func cells_for(
	id: String, origin: Vector2i, target: Vector2i, grid: GridSystem
) -> Array[Vector2i]:
	var s := shape_for(id)
	if s == null:
		var fallback: AreaShape = shape_for("single")
		return fallback.get_cells(origin, target, grid)
	return s.get_cells(origin, target, grid)


static func known_ids() -> Array:
	return BUILTINS.keys()
