class_name TerrainLayer
extends Node3D
# Camada de terreno plugável sobre o grid — obstáculos/custo/dano por dados (BoardLayoutResource).
# Opcional: sem layout, tudo fica default (livre, custo 1) — compatível com mapas antigos.

@export var layout: BoardLayoutResource

signal damage_floor_triggered(unit: Unit, cell: Vector2i, delta: int)


func setup(p_layout: BoardLayoutResource) -> void:
	layout = p_layout


func has_layout() -> bool:
	return layout != null


func is_blocked(cell: Vector2i) -> bool:
	return layout != null and layout.is_blocked(cell)


func blocks_sight(cell: Vector2i) -> bool:
	return layout != null and layout.blocks_sight(cell)


func move_cost(cell: Vector2i) -> int:
	return layout.move_cost(cell) if layout != null else 1


func on_unit_entered(unit: Unit, cell: Vector2i) -> void:
	if layout == null or not layout.is_damage_floor(cell):
		return
	if unit == null or unit.is_defeated():
		return
	unit.modify_stat("hp", layout.damage_delta)
	damage_floor_triggered.emit(unit, cell, layout.damage_delta)
