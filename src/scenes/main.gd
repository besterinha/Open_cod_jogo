extends Node


func _ready() -> void:
	get_tree().change_scene_to_file("res://src/scenes/combat_scene.tscn")
