class_name TacticalBoard
extends Node3D
# Board genérico — guarda grid, units, ocupação. Não tem lógica de dano.

@export var grid_size: Vector2i = Vector2i(8, 8)
@export var cell_size: float = 1.0

var grid: GridSystem
var units: Array[Unit] = []
var _occupancy: Dictionary = {} # Vector2i -> Unit

signal unit_added(unit: Unit)
signal unit_removed(unit: Unit)

func _ready() -> void:
	grid = GridSystem.new(grid_size, cell_size)

func add_unit(unit: Unit) -> void:
	units.append(unit)
	_occupancy[unit.cell] = unit
	add_child(unit)
	unit_added.emit(unit)
	unit.unit_defeated.connect(_on_unit_defeated)

func remove_unit(unit: Unit) -> void:
	units.erase(unit)
	_occupancy.erase(unit.cell)
	unit_removed.emit(unit)
	unit.queue_free()

func _on_unit_defeated(unit: Unit) -> void:
	print("[Board] %s derrotado" % unit.display_name)

func get_unit_at(cell: Vector2i) -> Unit:
	return _occupancy.get(cell) as Unit

func is_walkable(cell: Vector2i) -> bool:
	if not grid.is_within_bounds(cell):
		return false
	if _occupancy.has(cell):
		return false
	return true

func update_occupancy(unit: Unit, old_cell: Vector2i, new_cell: Vector2i) -> void:
	_occupancy.erase(old_cell)
	_occupancy[new_cell] = unit

func get_units_by_team(team: int) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.team == team and not u.is_defeated():
			out.append(u)
	return out

func is_victory(for_team: int) -> bool:
	var enemy_team: int = 1 if for_team == 0 else 0
	return get_units_by_team(enemy_team).is_empty()

func get_all_alive() -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if not u.is_defeated():
			out.append(u)
	return out
