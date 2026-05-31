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
const START_MENU_PATH     : String = "res://Escenas/StartMenu.tscn"

func _ready() -> void:
	btn_google = get_node_or_null("PanelContainer/MarginContainer/VBoxContainer/GoogleBtn")
	var btn_back : Button = get_node_or_null("BackBtn")
	if btn_back:
		btn_back.pressed.connect(func(): get_tree().change_scene_to_file(START_MENU_PATH))

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

	ProgressManager.user_id  = uid
	ProgressManager.is_guest = false
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
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)


func _on_to_register_pressed() -> void:
	get_tree().change_scene_to_file(REGISTER_SCENE_PATH)
