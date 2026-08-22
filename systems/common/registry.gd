extends Node
# Registry — Service Locator simples para sistemas plugáveis.
# Registra implementações de interfaces (ICaravanResourceSystem, ICombatResolver, etc.)
# Content nunca registra aqui, só systems no _ready.

var _services: Dictionary = {}

func register(id: String, impl: Object) -> void:
	_services[id] = impl

func get_service(id: String) -> Object:
	if not _services.has(id):
		push_warning("Registry: serviço não encontrado: %s" % id)
		return null
	return _services[id]

func has_service(id: String) -> bool:
	return _services.has(id)

func all_services() -> Dictionary:
	return _services.duplicate()
