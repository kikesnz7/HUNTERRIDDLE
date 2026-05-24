extends Control

@onready var email_input    : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CorreoInpt
@onready var password_input : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ContraInpt
@onready var confirm_input  : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ConfirmaInpt
@onready var btn_register   : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Registrar
@onready var btn_offline    : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button
@onready var btn_to_login   : Button   = $"PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Iniciar sesion"
@onready var msg_email      : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValCorr
@onready var msg_password   : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValContras
@onready var msg_session    : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValSesion

var nombre_input : LineEdit = null
var btn_google   : Button   = null

# Capturado en _on_register_pressed, consumido en _on_auth_success.
var _pending_display_name : String = ""

const LOGIN_SCENE : String = "res://Escenas/UI/Bocetos/LoginScreen.tscn"
const GAME_SCENE  : String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

func _ready() -> void:
	nombre_input = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/NombreInpt")
	btn_google   = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/GoogleBtn")

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
	if confirm_input.text != pass_:
		msg_password.text = "Las contraseñas no coinciden."
		return

	var nombre := ""
	if nombre_input != null:
		nombre = nombre_input.text.strip_edges()
	if nombre == "":
		nombre = email.split("@")[0]

	msg_email.text        = "Registrando cuenta..."
	btn_register.disabled = true
	_pending_display_name = nombre
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

	Supabase.access_token    = user_data.get("access_token", "")
	ProgressManager.user_id  = uid
	ProgressManager.is_guest = false
	ProgressManager.reset_for_new_session()

	# Crea la fila en profiles con email + display_name (is_admin/is_deleted=false por defecto).
	var user_email := ""
	if user_obj is Dictionary:
		user_email = user_obj.get("email", "")
	if user_email == "":
		user_email = email_input.text.strip_edges()
	var nombre := _pending_display_name
	_pending_display_name = ""
	await UserProfile.load_profile(uid, user_email, nombre)

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
	ProgressManager.reset_for_new_session()
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_to_login_pressed() -> void:
	get_tree().change_scene_to_file(LOGIN_SCENE)
