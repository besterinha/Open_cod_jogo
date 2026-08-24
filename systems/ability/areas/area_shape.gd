class_name AreaShape
extends Resource
# Estratégia plugável de forma de área (T2). Mecânica nova = novo script + .tres, Core intocado.
# origin = célula do usuário (direção p/ formas orientadas), target = célula mirada,
# grid = GridSystem p/ bounds. Retorna células afetadas (target incluído por convenção).


func get_cells(_origin: Vector2i, _target: Vector2i, _grid: GridSystem) -> Array[Vector2i]:
	return []


func shape_id() -> String:
	return "custom"
