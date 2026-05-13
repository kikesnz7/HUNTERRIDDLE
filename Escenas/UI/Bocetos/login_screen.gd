extends Control

@onready var email_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CorreoInpt
@onready var password_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ContraInpt
@onready var btn_login: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button
@onready var btn_offline: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button2
@onready var btn_exit: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Button
@onready var Msg_corr: Label = $PanelContainer/MarginContainer/VBoxContainer/ValCorr
@onready var Msg_sess: Label = $PanelContainer/MarginContainer/VBoxContainer/ValSesion

const NEXT_SCENE_PATH: String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

func _ready() -> void:
	Supabase.auth_success.connect(_on_auth_success)
	Supabase.auth_error.connect(_on_auth_error)
	btn_login.pressed.connect(_on_login_btn_pressed)
	btn_offline.pressed.connect(_on_offline_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

func _on_login_btn_pressed() -> void:
	if email_input.text.strip_edges() == "" or password_input.text == "":
		Msg_corr.text = "Completa todos los campos."
		return
	Msg_corr.text = "Iniciando sesión..."
	btn_login.disabled = true
	Supabase.sign_in(email_input.text.strip_edges(), password_input.text)

func _on_auth_success(_user_data: Dictionary) -> void:
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)

func _on_auth_error(msg: String) -> void:
	btn_login.disabled = false
	Msg_corr.text = ""
	Msg_sess.text = "Error: " + msg

func _on_offline_pressed() -> void:
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)

func _on_exit_pressed() -> void:
	get_tree().quit()
