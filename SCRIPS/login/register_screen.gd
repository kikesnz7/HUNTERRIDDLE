extends Control

@onready var email_input    : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CorreoInpt
@onready var password_input : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ContraInpt
@onready var btn_register   : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Registrar
@onready var btn_offline    : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button
@onready var btn_to_login   : Button   = $"PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Iniciar sesion"
@onready var msg_email      : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValCorr
@onready var msg_password   : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValContras
@onready var msg_session    : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValSesion

var nombre_input : LineEdit = null
var btn_google   : Button   = null

const LOGIN_SCENE : String = "res://Escenas/UI/Bocetos/LoginScreen.tscn"
const GAME_SCENE  : String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

func _ready() -> void:
	nombre_input = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/NombreInpt")
	btn_google   = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/GoogleBtn")
	var btn_back : Button = get_node_or_null("BackBtn")
	if btn_back:
		btn_back.pressed.connect(func(): get_tree().change_scene_to_file(LOGIN_SCENE))

	Supabase.auth_success.connect(_on_auth_success)
	Supabase.auth_error.connect(_on_auth_error)
	btn_register.pressed.connect(_on_register_pressed)
	btn_offline.pressed.connect(_on_offline_pressed)
	btn_to_login.pressed.connect(_on_to_login_pressed)
	if btn_google:
		btn_google.pressed.connect(_on_google_pressed)


func _on_register_pressed() -> void:
	var email := email_input.text.strip_edges()
	var pass_ := password_input.text

	msg_email.text    = ""
	msg_password.text = ""
	msg_session.text  = ""

	if email == "":
		msg_email.text = "El correo no puede estar vacío."
		return
	if "@" not in email:
		msg_email.text = "Introduce un correo válido."
		return
	if pass_ == "":
		msg_password.text = "La contraseña no puede estar vacía."
		return
	if pass_.length() < 6:
		msg_password.text = "Mínimo 6 caracteres."
		return

	var nombre := ""
	if nombre_input != null:
		nombre = nombre_input.text.strip_edges()
	if nombre == "":
		nombre = email.split("@")[0]

	msg_email.text        = "Registrando cuenta..."
	btn_register.disabled = true
	Supabase.sign_up(email, pass_, nombre)


func _on_google_pressed() -> void:
	msg_session.text     = "Abriendo autenticación con Google..."
	btn_google.disabled  = true
	Supabase.sign_in_with_google()


func _on_auth_success(user_data: Dictionary) -> void:
	var uid      := ""
	var user_obj = user_data.get("user", null)
	if user_obj is Dictionary:
		uid = user_obj.get("id", "")
	if uid == "":
		uid = user_data.get("id", "")

	if uid == "":
		msg_session.text      = "Error: no se pudo obtener el ID de usuario."
		btn_register.disabled = false
		if btn_google:
			btn_google.disabled = false
		return

	ProgressManager.user_id  = uid
	ProgressManager.is_guest = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_auth_error(msg: String) -> void:
	btn_register.disabled = false
	if btn_google:
		btn_google.disabled = false
	msg_email.text = ""
	if "already registered" in msg.to_lower() or "already exists" in msg.to_lower():
		msg_session.text = "Este correo ya está registrado. Prueba a iniciar sesión."
	else:
		msg_session.text = "Error: " + msg


func _on_offline_pressed() -> void:
	Supabase.access_token    = "invitado"
	ProgressManager.user_id  = ""
	ProgressManager.is_guest = true
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_to_login_pressed() -> void:
	get_tree().change_scene_to_file(LOGIN_SCENE)
