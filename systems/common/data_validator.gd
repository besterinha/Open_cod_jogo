class_name DataValidator
extends RefCounted
# DataValidator — valida Resources plugáveis antes de aceitar.
# Usado por GUT + godot-validation-flow + CI. IA nunca passa sem isso.

const ALLOWED_AREAS: Array[String] = ["single", "3x3", "cross", "line"]


static func validate_ability(res: Resource, db: AttributeDatabase = null) -> Array[String]:
	var errs: Array[String] = []
	if res == null:
		errs.append("Resource nulo")
		return errs
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
	var area_shape: AreaShape = res.get("area_shape") if "area_shape" in res else null
	if area_shape != null:
		# T2: shape custom plugado — string legada ignorada se vazia; valida script da interface
		if not area_shape.has_method("get_cells"):
			errs.append("area_shape sem get_cells(origin,target,grid)")
	elif area != "" and area not in ALLOWED_AREAS:
		errs.append(
			"area inválida: %s (permitido: %s ou area_shape)" % [area, ", ".join(ALLOWED_AREAS)]
		)
	var custo = res.get("custo") if "custo" in res else null
	if custo != null and typeof(custo) == TYPE_DICTIONARY:
		for k in custo.keys():
			if int(custo[k]) < 0:
				errs.append("custo[%s] negativo" % k)
			if db != null and not db.is_valid_id(str(k)):
				errs.append("custo stat_id desconhecido: %s (defina em data/stats/*.tres)" % k)
	var efeitos = res.get("efeitos") if "efeitos" in res else null
	if efeitos is Array:
		if efeitos.is_empty():
			errs.append("efeitos vazio")
		for e in efeitos:
			if e is Dictionary:
				var sid: String = str(e.get("stat_id", ""))
				if sid.is_empty():
					errs.append("efeito sem stat_id")
				elif db != null and not db.is_valid_id(sid):
					errs.append("efeito stat_id desconhecido: %s" % sid)
				var delta: Variant = e.get("delta", null)
				if delta == null or (int(delta) == 0 and str(delta) != "0"):
					errs.append("efeito sem delta para %s" % sid)
	var vfx = res.get("vfx") if "vfx" in res else null
	if vfx != null and vfx is PackedScene:
		# vfx é PackedScene já carregada — verifica se path existe via resource_path
		var path: String = (vfx as PackedScene).resource_path
		if path != "" and not ResourceLoader.exists(path):
			errs.append("vfx PackedScene path inexistente: %s" % path)
	var logic = res.get("logic_script") if "logic_script" in res else null
	if logic != null and logic is GDScript:
		var scr: GDScript = logic as GDScript
		if scr.resource_path != "" and not ResourceLoader.exists(scr.resource_path):
			errs.append("logic_script path inexistente: %s" % scr.resource_path)
		# verifica se tem can_activate/activate (contrato IAbilityLogic)
		var inst: Variant = null
		var can_create: bool = true
		# evita instanciar se script tem erro
		if scr.can_instantiate():
			inst = scr.new()
			if inst and not inst.has_method("can_activate"):
				errs.append("logic_script sem can_activate")
			if inst and not inst.has_method("activate"):
				errs.append("logic_script sem activate")
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


static func is_valid_ability(res: Resource, db: AttributeDatabase = null) -> bool:
	return validate_ability(res, db).is_empty()


static func is_valid_event(res: Resource) -> bool:
	return validate_event(res).is_empty()
