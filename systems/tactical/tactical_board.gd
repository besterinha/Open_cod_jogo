class_name TacticalBoard
extends Node3D
# Board genérico — guarda grid, units, ocupação. Não tem lógica de dano.

@export var grid_size: Vector2i = Vector2i(8, 8)
@export var cell_size: float = 1.0

var grid: GridSystem
var units: Array[Unit] = []
var terrain: TerrainLayer = null  # opcional — null = grid todo livre (compat)
var _occupancy: Dictionary = {}  # Vector2i -> Unit

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
	_occupancy.erase(unit.cell)
	# esconde visual mas mantém em units para histórico; is_walkable já ignora derrotados
	unit.visible = false
	# opcional: liberar célula para movimento
	unit_removed.emit(unit)


func get_unit_at(cell: Vector2i) -> Unit:
	return _occupancy.get(cell) as Unit


func is_walkable(cell: Vector2i) -> bool:
	if not grid.is_within_bounds(cell):
		return false
	if terrain != null and terrain.is_blocked(cell):
		return false
	if _occupancy.has(cell):
		var occ: Unit = _occupancy[cell] as Unit
		if occ and occ.is_defeated():
			return true  # célula de morto é andável
		return false
	return true


func update_occupancy(unit: Unit, old_cell: Vector2i, new_cell: Vector2i) -> void:
	if _occupancy.has(new_cell):
		var existing: Unit = _occupancy[new_cell] as Unit
		if existing and not existing.is_defeated() and existing != unit:
			push_warning(
				(
					"[Board] update_occupancy: célula %s já ocupada por %s"
					% [new_cell, existing.display_name]
				)
			)
			return
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
