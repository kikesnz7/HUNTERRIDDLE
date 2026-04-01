extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_entrar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Menu.tscn")

func _on_config_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Config.tscn")

func _on_idioma_pressed() -> void:
	pass # Replace with function body.

func _on_salir_pressed() -> void:
	get_tree().quit()
