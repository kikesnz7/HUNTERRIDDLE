extends CanvasLayer

@onready var btn_volver : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Volver

const CONFIG_PATH : String = "res://Escenas/Config.tscn"

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(CONFIG_PATH)
