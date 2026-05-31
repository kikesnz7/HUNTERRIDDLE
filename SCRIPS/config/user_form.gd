extends CanvasLayer

@onready var titulo         : Label    = $MarginContainer/Panel/MarginContainer/VBoxContainer/HeaderRow/Titulo
@onready var btn_cancelar   : Button   = $MarginContainer/Panel/MarginContainer/VBoxContainer/HeaderRow/BtnCancelar
@onready var field_nombre   : LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/FieldNombre
@onready var seccion_crear  : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/SeccionCrear
@onready var field_email    : LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/SeccionCrear/FieldEmail
@onready var field_password : LineEdit = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/SeccionCrear/FieldPassword
@onready var check_admin    : CheckBox = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/CheckAdmin
@onready var check_activa   : CheckBox = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/CamposVBox/CheckActiva
@onready var msg_estado     : Label    = $MarginContainer/Panel/MarginContainer/VBoxContainer/MsgEstado
@onready var btn_guardar    : Button   = $MarginContainer/Panel/MarginContainer/VBoxContainer/BtnGuardar

const USERS_ADMIN_PATH : String = "res://Escenas/UI/UsersAdmin.tscn"

var _mode : String = ""
var _uid  : String = ""


func _ready() -> void:
	_mode = GameState.user_form_mode
	btn_cancelar.pressed.connect(_on_cancelar_pressed)
	btn_guardar.pressed.connect(_on_guardar_pressed)

	if _mode == "edit":
		titulo.text = "Editar usuario"
		btn_guardar.text = "Guardar"
		seccion_crear.visible = false
		check_activa.visible = true
		_precargar_datos()
	else:
		titulo.text = "Nuevo usuario"
		btn_guardar.text = "Crear usuario"
		seccion_crear.visible = true
		check_activa.visible = false


func _precargar_datos() -> void:
	var data := GameState.user_form_data
	_uid = String(data.get("user_id", ""))
	field_nombre.text = String(data.get("display_name", ""))
	check_admin.button_pressed = bool(data.get("is_admin", false))
	check_activa.button_pressed = not bool(data.get("is_deleted", false))


func _on_cancelar_pressed() -> void:
	get_tree().change_scene_to_file(USERS_ADMIN_PATH)


func _on_guardar_pressed() -> void:
	btn_guardar.disabled = true
	msg_estado.text = ""

	if _mode == "edit":
		await _guardar_edicion()
	else:
		await _crear_usuario()

	btn_guardar.disabled = false


func _guardar_edicion() -> void:
	if _uid == "":
		msg_estado.text = "Error: usuario no identificado."
		return

	var data := {
		"display_name": field_nombre.text.strip_edges(),
		"is_admin":     check_admin.button_pressed,
		"is_deleted":   not check_activa.button_pressed,
	}
	var ok = await SupabaseClient.update_row("profiles", "user_id=eq.%s" % _uid, data)
	if not ok:
		msg_estado.text = "Error al guardar. Intenta de nuevo."
		return

	get_tree().change_scene_to_file(USERS_ADMIN_PATH)


func _crear_usuario() -> void:
	var email  := field_email.text.strip_edges()
	var pass_  := field_password.text
	var nombre := field_nombre.text.strip_edges()

	if email == "" or "@" not in email:
		msg_estado.text = "Email inválido."
		return
	if pass_.length() < 6:
		msg_estado.text = "La contraseña debe tener al menos 6 caracteres."
		return

	msg_estado.text = "Creando usuario..."
	var new_uid = await SupabaseClient.admin_create_user(email, pass_, nombre, check_admin.button_pressed)
	if new_uid == "":
		msg_estado.text = "No se pudo crear el usuario. ¿Email ya en uso?"
		return

	var row := {
		"user_id":      new_uid,
		"email":        email,
		"display_name": nombre,
		"is_admin":     check_admin.button_pressed,
	}
	var ok = await SupabaseClient.upsert("profiles", row, "user_id")
	if not ok:
		msg_estado.text = "Usuario creado en Auth pero el perfil falló. Verifica en la lista."
		await get_tree().create_timer(2.0).timeout

	get_tree().change_scene_to_file(USERS_ADMIN_PATH)
