extends CanvasLayer

@onready var slider_volumen     : HSlider = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/HBoxContainer/HSlider
@onready var btn_estrellas      : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/EstrellasGlobales
@onready var btn_progreso       : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/ProgresoUsuarios
@onready var btn_administrar    : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/AdministrarUsuarios
@onready var btn_tema           : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Tema
@onready var btn_volver         : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Volver

const SETTINGS_PATH    : String = "user://settings.cfg"
const START_MENU_PATH  : String = "res://Escenas/StartMenu.tscn"
const GLOBAL_STARS_PATH: String = "res://Escenas/UI/GlobalStars.tscn"
const USERS_PROGRESS_PATH: String = "res://Escenas/UI/UsersProgress.tscn"
const USERS_ADMIN_PATH : String = "res://Escenas/UI/UsersAdmin.tscn"

func _ready() -> void:
	_load_volume_into_slider()
	slider_volumen.value_changed.connect(_on_volume_changed)
	btn_volver.pressed.connect(_on_volver_pressed)
	btn_estrellas.pressed.connect(_on_estrellas_pressed)
	btn_progreso.pressed.connect(_on_progreso_pressed)
	btn_administrar.pressed.connect(_on_administrar_pressed)

	btn_tema.disabled = true

	# Solo los administradores ven los botones de gestión de usuarios.
	btn_progreso.visible    = UserProfile.is_admin
	btn_administrar.visible = UserProfile.is_admin

func _load_volume_into_slider() -> void:
	var cfg := ConfigFile.new()
	var v: float = 1.0
	if cfg.load(SETTINGS_PATH) == OK:
		v = cfg.get_value("audio", "master_volume", 1.0)
	slider_volumen.value = clampf(v, 0.0, 1.0)
	_apply_volume(slider_volumen.value)

func _on_volume_changed(value: float) -> void:
	_apply_volume(value)
	_save_volume(value)

func _apply_volume(value: float) -> void:
	var v = clampf(value, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(v))

func _save_volume(value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("audio", "master_volume", value)
	cfg.save(SETTINGS_PATH)

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
