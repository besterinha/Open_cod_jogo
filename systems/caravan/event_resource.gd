class_name EventResource
extends Resource
# Resource plugável para eventos de caravana.
# IA gera .tres/event_*.tres, nunca edita systems/.

@export var id: String = ""
@export var weight: int = 10
@export var trigger: String = "random"  # random, city, camp
@export var titulo: String = ""
@export var texto: String = ""
@export var escolhas: Array[EventChoice] = []


func is_valid() -> bool:
	return not id.is_empty() and not escolhas.is_empty()
