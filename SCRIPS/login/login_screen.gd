extends Control

@onready var email_input     : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CorreoInpt
@onready var password_input  : LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ContraInpt
@onready var btn_login       : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button
@onready var btn_offline     : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button2
@onready var btn_to_register : Button   = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Registrarse
@onready var msg_corr        : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValCorr
@onready var msg_sess        : Label    = $PanelContainer/MarginContainer/VBoxContainer/ValSesion

var btn_google : Button = null

const NEXT_SCENE_PATH     : String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"
const REGISTER_SCENE_PATH : String = "res://Escenas/UI/Bocetos/RegisterScreen.tscn"

func _ready() -> void:
	btn_google = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/GoogleBtn")

	Supabase.auth_success.connect(_on_auth_success)
	Supabase.auth_error.connect(_on_auth_error)
	btn_login.pressed.connect(_on_login_btn_pressed)
	btn_offline.pressed.connect(_on_offline_pressed)
	btn_to_register.pressed.connect(_on_to_register_pressed)
	if btn_google:
		btn_google.pressed.connect(_on_google_pressed)


func _on_login_btn_pressed() -> void:
	if email_input.text.strip_edges() == "" or password_input.text == "":
		msg_corr.text = "Completa todos los campos."
		return
	msg_corr.text = "Iniciando sesión..."
	btn_login.disabled = true
	Supabase.sign_in(email_input.text.strip_edges(), password_input.text)


func _on_google_pressed() -> void:
	msg_corr.text = "Abriendo autenticación con Google..."
	btn_google.disabled = true
	Supabase.sign_in_with_google()


func _on_auth_success(user_data: Dictionary) -> void:
	var uid      := ""
	var user_obj = user_data.get("user", null)
	if user_obj is Dictionary:
		uid = user_obj.get("id", "")
	if uid == "":
		uid = user_data.get("id", "")

	if uid == "":
		msg_sess.text = "Error: no se pudo obtener el ID de usuario."
		btn_login.disabled = false
		if btn_google:
			btn_google.disabled = false
		return

	Supabase.access_token    = user_data.get("access_token", "")
	ProgressManager.user_id  = uid
	ProgressManager.is_guest = false
	ProgressManager.reset_for_new_session()

	# Carga (o crea) el perfil del usuario para obtener email + flag is_admin.
	# Si Supabase devuelve user_metadata.nombre (lo guarda sign_up), lo propagamos.
	var user_email := ""
	var nombre := ""
	if user_obj is Dictionary:
		user_email = user_obj.get("email", "")
		var meta = user_obj.get("user_metadata", null)
		if meta is Dictionary:
			nombre = String(meta.get("nombre", ""))
	if user_email == "":
		user_email = email_input.text.strip_edges()
	await UserProfile.load_profile(uid, user_email, nombre)

	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _on_auth_error(msg: String) -> void:
	btn_login.disabled = false
	if btn_google:
		btn_google.disabled = false
	msg_corr.text = ""
	msg_sess.text = "Error: " + msg


func _on_offline_pressed() -> void:
	Supabase.access_token = "invitado"
	ProgressManager.user_id  = ""
	ProgressManager.is_guest = true
	ProgressManager.reset_for_new_session()
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _on_to_register_pressed() -> void:
	get_tree().change_scene_to_file(REGISTER_SCENE_PATH)
