class_name BoardLayoutResource
extends Resource
# Layout de terreno plugável data-driven — tokens por linha, amigável p/ IA gerar (TDD #schema-ia).
# Tokens: "." normal | "#" bloqueado (muro, bloqueia movimento E visão) |
#         "2".."9" custo de movimento da célula | "^" piso de dano (usa damage_delta)
# Célula fora do layout = default (custo 1, livre). Size deve bater com linhas/colunas.

@export var size: Vector2i = Vector2i(8, 8)
@export var rows: PackedStringArray = []
@export var damage_delta: int = -2  # dano do piso "^" por entrada


func token_at(cell: Vector2i) -> String:
	if not is_within_bounds(cell):
		return "."
	if cell.y >= rows.size() or cell.x >= rows[cell.y].length():
		return "."
	return rows[cell.y][cell.x]


func is_blocked(cell: Vector2i) -> bool:
	return token_at(cell) == "#"


func move_cost(cell: Vector2i) -> int:
	var t: String = token_at(cell)
	if t == "#" or t == "." or t == "^":
		return 1
	var v: int = t.to_int()
	return maxi(1, v)


func is_damage_floor(cell: Vector2i) -> bool:
	return token_at(cell) == "^"


func is_within_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < size.x and cell.y >= 0 and cell.y < size.y


func blocks_sight(cell: Vector2i) -> bool:
	return is_blocked(cell)


static func validate(layout: BoardLayoutResource) -> Array[String]:
	var errs: Array[String] = []
	if layout.size.x <= 0 or layout.size.y <= 0:
		errs.append("size inválido: %s" % str(layout.size))
		return errs
	if layout.rows.size() != layout.size.y:
		errs.append("rows (%d) != size.y (%d)" % [layout.rows.size(), layout.size.y])
	for y in layout.rows.size():
		if layout.rows[y].length() != layout.size.x:
			errs.append(
				"linha %d tem %d colunas, esperado %d" % [y, layout.rows[y].length(), layout.size.x]
			)
		for x in layout.rows[y].length():
			var t: String = layout.rows[y][x]
			if t != "." and t != "#" and t != "^" and not (t >= "2" and t <= "9"):
				errs.append("token inválido '%s' em (%d,%d)" % [t, x, y])
	return errs
