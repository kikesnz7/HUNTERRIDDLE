extends CanvasLayer

@onready var msg_Titulo      : Label   =$VBoxContainer/MarginContainer/Titulo
@onready var btn_entrar      : Button   =$VBoxContainer/MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Entrar
@onready var btn_config      : Button   =$VBoxContainer/MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Config
@onready var btn_idioma      : Button   =$VBoxContainer/MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Idioma
@onready var btn_salir      : Button   =$VBoxContainer/MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Salir
@onready var msg_mensaje      : Label= $VBoxContainer/HBoxContainer/Mensaje
@onready var btn_iniciar      : Button   =$"VBoxContainer/MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Iniciar Sesion"
const NEXT_SCENE_PATH : String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"
const PATHLOGIN:String ="res://Escenas/UI/Bocetos/LoginScreen.tscn"
const PATHCONFIG:String ="res://Escenas/Config.tscn"
const SETTINGS_PATH:String ="user://settings.cfg"

func _ready() -> void:
	_apply_saved_volume()
	Supabase.auth_success.connect(_on_auth_success)
	Supabase.auth_error.connect(_on_auth_error)
	btn_entrar.pressed.connect(_on_enter_btn_pressed)
	#btn_offline.pressed.connect(_on_offline_pressed)
	btn_salir.pressed.connect(_on_exit_pressed)
	btn_iniciar.pressed.connect(_on_iniciar_btn_pressed)
	btn_config.pressed.connect(_on_config_btn_pressed)

func _on_config_btn_pressed() -> void:
	get_tree().change_scene_to_file(PATHCONFIG)

func _apply_saved_volume() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var v: float = cfg.get_value("audio", "master_volume", 1.0)
	v = clampf(v, 0.0001, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(v))
func _on_enter_btn_pressed() -> void:
	btn_entrar.disabled = true
	if(Supabase.access_token):
		msg_mensaje.text = "Entrando..."
		await get_tree().create_timer(1.2).timeout
		get_tree().change_scene_to_file(NEXT_SCENE_PATH)
		return
	msg_mensaje.text= "Redirigiendo a login..."
	await get_tree().create_timer(1.2).timeout
	get_tree().change_scene_to_file(PATHLOGIN)

func _on_iniciar_btn_pressed() -> void:
	btn_iniciar.disabled = true
	get_tree().change_scene_to_file(PATHLOGIN)
func _on_auth_success(user_data: Dictionary) -> void:
	# Extrae el user_id del diccionario que devuelve el plugin
	# El plugin de Supabase para Godot devuelve el user en user_data["user"]
	var uid = ""
	if user_data.has("user") and user_data["user"].has("id"):
		uid = user_data["user"]["id"]
	elif user_data.has("id"):
		# Algunos plugins devuelven el user directamente sin anidar
		uid = user_data["id"]
 
	if uid == "":
		msg_mensaje.text = "Error: no se pudo obtener el ID de usuario."
		btn_entrar.disabled = false
		return
 
	# Configura el ProgressManager con el usuario autenticado
	ProgressManager.user_id  = uid
	ProgressManager.is_guest = false
 
	msg_mensaje.text = "Sesión iniciada correctamente."
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
 
func _on_auth_error(msg: String) -> void:
	btn_entrar.disabled = false
	msg_mensaje.text  = "Error: " + msg
 
func _on_offline_pressed() -> void:
	# Modo invitado — progreso local, se pierde al cerrar
	ProgressManager.user_id  = ""
	ProgressManager.is_guest = true
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)
 
func _on_exit_pressed() -> void:
	get_tree().quit()
