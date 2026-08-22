extends Node3D
# Cena 2.5D tática placeholder — grid 8x8 com 2 cápsulas.
# Troca placeholder por Sprite3D/modelo é só trocar packedScene no .tres.

var grid: GridSystem = GridSystem.new(Vector2i(8, 8), 1.0)

func _ready() -> void:
	print("[TacticalArena] Grid %s pronto. 2 unidades posicionadas." % grid.size)
	# Spawn tiles placeholder (8x8 cubos)
	for x in 8:
		for y in 8:
			var tile: Node3D = preload("res://placeholders/tactical/tile_cube.tscn").instantiate()
			tile.position = grid.cell_to_world(Vector2i(x, y))
			# cor xadrez
			var mesh: MeshInstance3D = tile as MeshInstance3D
			if ((x + y) % 2) == 0:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.3, 0.3, 0.32)
				mesh.material_override = mat
			else:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(0.25, 0.25, 0.27)
				mesh.material_override = mat
			$Grid.add_child(tile)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		var cam: Camera3D = $Camera3D
		var from: Vector3 = cam.project_ray_origin(event.position)
		var dir: Vector3 = cam.project_ray_normal(event.position)
		# interseção com plano y=0
		var t: float = -from.y / dir.y if dir.y != 0 else 0
		var hit: Vector3 = from + dir * t
		var cell: Vector2i = grid.world_to_cell(hit)
		if grid.is_within_bounds(cell):
			print("[Input] Tap em cell %s (world %s)" % [cell, hit])
