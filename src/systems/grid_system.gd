extends Node2D
class_name GridSystem

const GRID_SIZE: Vector2i = Vector2i(10, 10)
const TILE_SIZE: Vector2i = Vector2i(32, 16)

var grid_data: Array = []


func _ready() -> void:
	_init_grid()


func _init_grid() -> void:
	grid_data.clear()
	for x in range(GRID_SIZE.x):
		grid_data.append([])
		for y in range(GRID_SIZE.y):
			grid_data[x].append(0)


func is_within_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < GRID_SIZE.x and pos.y >= 0 and pos.y < GRID_SIZE.y


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
