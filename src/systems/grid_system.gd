extends Node2D
class_name GridSystem

const TILE_SIZE: Vector2i = Vector2i(32, 16)

var grid_size: Vector2i = Vector2i(8, 8)
var grid_data: Array = []
var highlighted_cell: Vector2i = Vector2i(-1, -1)


func _ready() -> void:
	setup(grid_size)


func setup(size: Vector2i) -> void:
	grid_size = size
	_init_grid()
	highlighted_cell = Vector2i(-1, -1)
	queue_redraw()


func _init_grid() -> void:
	grid_data.clear()
	for x in range(grid_size.x):
		grid_data.append([])
		for y in range(grid_size.y):
			grid_data[x].append(0)


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y


func world_to_grid(world_pos: Vector2) -> Vector2i:
	var half_x := TILE_SIZE.x / 2.0
	var half_y := TILE_SIZE.y / 2.0
	var grid_x := int(floor((world_pos.x / half_x + world_pos.y / half_y) / 2.0))
	var grid_y := int(floor((world_pos.y / half_y - world_pos.x / half_x) / 2.0))
	return Vector2i(grid_x, grid_y)


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	var half_x := TILE_SIZE.x / 2.0
	var half_y := TILE_SIZE.y / 2.0
	var world_x := (grid_pos.x - grid_pos.y) * half_x
	var world_y := (grid_pos.x + grid_pos.y) * half_y
	return Vector2(world_x, world_y)


func highlight_cell(pos: Vector2i) -> void:
	highlighted_cell = pos
	queue_redraw()


func _draw() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var pos := Vector2i(x, y)
			var world_pos := grid_to_world(pos)
			var is_hl := pos == highlighted_cell
			if is_hl:
				_draw_tile(world_pos, Color(1.0, 1.0, 0.0, 0.5), Color(1.0, 1.0, 0.0))
			else:
				var val: int = grid_data[x][y]
				var color: Color = Color(0.7, 0.7, 0.7) if val == 0 else Color(0.5, 0.2, 0.2)
				_draw_tile(world_pos, color, Color(0.3, 0.3, 0.3))


func _draw_tile(center: Vector2, color: Color, border: Color) -> void:
	var half_w: float = TILE_SIZE.x * 0.5
	var half_h: float = TILE_SIZE.y * 0.5
	var verts: PackedVector2Array = [
		Vector2(center.x, center.y - half_h),
		Vector2(center.x + half_w, center.y),
		Vector2(center.x, center.y + half_h),
		Vector2(center.x - half_w, center.y),
	]
	draw_colored_polygon(verts, color)
	var closed_verts: PackedVector2Array = verts
	closed_verts.append(verts[0])
	draw_polyline(closed_verts, border, 1.0)
