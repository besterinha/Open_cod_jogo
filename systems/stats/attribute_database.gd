extends Resource
class_name AttributeDatabase
# Coleção de AttributeDefinition — carregado de data/stats/*.tres
# Registry lê daqui para validar qualquer custo/efeito.

@export var attributes: Array[AttributeDefinition] = []

func get_ids() -> Array[String]:
	var ids: Array[String] = []
	for a in attributes:
		ids.append(a.id)
	return ids

func get_def(id: String) -> AttributeDefinition:
	for a in attributes:
		if a.id == id:
			return a
	return null

func is_valid_id(id: String) -> bool:
	return get_def(id) != null

func clamp_value(id: String, v: int) -> int:
	var d := get_def(id)
	if d == null:
		return v
	return clamp(v, d.min_value, d.max_value)

func validate() -> Array[String]:
	var errs: Array[String] = []
	var seen: Dictionary = {}
	for a in attributes:
		if a.id.is_empty():
			errs.append("Attribute com id vazio: %s" % a.nome)
		if seen.has(a.id):
			errs.append("Attribute id duplicado: %s" % a.id)
		seen[a.id] = true
		if a.min_value > a.max_value:
			errs.append("min > max para %s" % a.id)
	return errs
