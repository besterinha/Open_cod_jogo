extends RefCounted
# DataValidator — valida Resources plugáveis antes de aceitar.
# Usado por GUT + godot-validation-flow + CI. IA nunca passa sem isso.
class_name DataValidator

const ALLOWED_AREAS: Array[String] = ["single", "3x3", "cross", "line"]

static func validate_ability(res: Resource) -> Array[String]:
	var errs: Array[String] = []
	if res == null:
		errs.append("Resource nulo")
		return errs
	# checa propriedades via get (não tipado, pois Resource genérico)
	var id: String = res.get("id") if "id" in res else ""
	if id.is_empty():
		errs.append("id vazio")
	var nome: String = res.get("nome") if "nome" in res else ""
	if nome.is_empty():
		errs.append("nome vazio")
	var alcance: int = int(res.get("alcance")) if "alcance" in res else 0
	if alcance < 0 or alcance > 10:
		errs.append("alcance fora de 0..10: %d" % alcance)
	var area: String = res.get("area") if "area" in res else ""
	if area != "" and area not in ALLOWED_AREAS:
		errs.append("area inválida: %s (permitido: %s)" % [area, ", ".join(ALLOWED_AREAS)])
	var custo = res.get("custo") if "custo" in res else null
	if custo != null and typeof(custo) == TYPE_DICTIONARY:
		for k in custo.keys():
			if int(custo[k]) < 0:
				errs.append("custo[%s] negativo" % k)
	return errs

static func validate_event(res: Resource) -> Array[String]:
	var errs: Array[String] = []
	if res == null:
		errs.append("Resource nulo")
		return errs
	var id: String = res.get("id") if "id" in res else ""
	if id.is_empty():
		errs.append("id vazio")
	var weight: int = int(res.get("weight")) if "weight" in res else 0
	if weight < 0:
		errs.append("weight negativo")
	var escolhas = res.get("escolhas") if "escolhas" in res else []
	if escolhas is Array and escolhas.is_empty():
		errs.append("evento sem escolhas")
	return errs

static func is_valid_ability(res: Resource) -> bool:
	return validate_ability(res).is_empty()

static func is_valid_event(res: Resource) -> bool:
	return validate_event(res).is_empty()
