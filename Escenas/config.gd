extends CanvasLayer

@onready var btn_sonido      : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Sonido
@onready var btn_estrellas   : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/EstrellasGlobales
@onready var btn_progreso    : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/ProgresoUsuarios
@onready var btn_administrar : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/AdministrarUsuarios
@onready var btn_tema        : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Tema
@onready var btn_volver      : Button = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Volver

const START_MENU_PATH     : String = "res://Escenas/StartMenu.tscn"
const SOUND_SETTINGS_PATH : String = "res://Escenas/UI/SoundSettings.tscn"
const GLOBAL_STARS_PATH   : String = "res://Escenas/UI/GlobalStars.tscn"
const USERS_PROGRESS_PATH : String = "res://Escenas/UI/UsersProgress.tscn"
const USERS_ADMIN_PATH    : String = "res://Escenas/UI/UsersAdmin.tscn"

func _ready() -> void:
	btn_sonido.pressed.connect(_on_sonido_pressed)
	btn_volver.pressed.connect(_on_volver_pressed)
	btn_estrellas.pressed.connect(_on_estrellas_pressed)
	btn_progreso.pressed.connect(_on_progreso_pressed)
	btn_administrar.pressed.connect(_on_administrar_pressed)

	btn_tema.disabled = true

	btn_progreso.visible    = UserProfile.is_admin
	btn_administrar.visible = UserProfile.is_admin

func _on_sonido_pressed() -> void:
	get_tree().change_scene_to_file(SOUND_SETTINGS_PATH)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(START_MENU_PATH)

func _on_estrellas_pressed() -> void:
	get_tree().change_scene_to_file(GLOBAL_STARS_PATH)

func _on_progreso_pressed() -> void:
	if not UserProfile.is_admin:
		return
	get_tree().change_scene_to_file(USERS_PROGRESS_PATH)

func _on_administrar_pressed() -> void:
	if not UserProfile.is_admin:
		return
	get_tree().change_scene_to_file(USERS_ADMIN_PATH)
