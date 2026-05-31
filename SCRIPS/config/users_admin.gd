extends CanvasLayer

@onready var lista       : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/Lista
@onready var btn_anadir  : Button        = $MarginContainer/Panel/MarginContainer/VBoxContainer/Footer/BtnAnadir
@onready var btn_volver  : Button        = $MarginContainer/Panel/MarginContainer/VBoxContainer/Footer/BtnVolver
@onready var msg_estado  : Label         = $MarginContainer/Panel/MarginContainer/VBoxContainer/Estado

const CONFIG_PATH    : String = "res://Escenas/Config.tscn"
const USER_FORM_PATH : String = "res://Escenas/UI/UserForm.tscn"

const COLOR_ONLINE  : Color = Color(0.30, 0.85, 0.40)
const COLOR_OFFLINE : Color = Color(0.55, 0.55, 0.55)

var _info_dialog        : AcceptDialog
var _confirm_dialog     : ConfirmationDialog
var _pending_delete_uid : String = ""


func _ready() -> void:
	if not UserProfile.is_admin:
		msg_estado.text = "Acceso restringido. Volviendo..."
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(CONFIG_PATH)
		return

	_info_dialog = AcceptDialog.new()
	_info_dialog.unresizable = true
	add_child(_info_dialog)

	_confirm_dialog = ConfirmationDialog.new()
	_confirm_dialog.title = "Confirmar"
	_confirm_dialog.ok_button_text = "Eliminar"
	_confirm_dialog.cancel_button_text = "Cancelar"
	_confirm_dialog.confirmed.connect(_on_confirm_eliminar)
	add_child(_confirm_dialog)

	btn_volver.pressed.connect(_on_volver_pressed)
	btn_anadir.pressed.connect(_on_anadir_pressed)
	msg_estado.text = "Cargando usuarios..."
	await _refrescar()


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(CONFIG_PATH)


func _on_anadir_pressed() -> void:
	GameState.user_form_mode = "create"
	GameState.user_form_data = {}
	get_tree().change_scene_to_file(USER_FORM_PATH)


# ─────────────────────────────────────────────
# Lista
# ─────────────────────────────────────────────

func _refrescar() -> void:
	var rows = await SupabaseClient.get_rows("profiles", "")
	rows.sort_custom(func(a, b):
		var dela := bool(a.get("is_deleted", false))
		var delb := bool(b.get("is_deleted", false))
		if dela != delb:
			return not dela
		var la := String(UserProfile.display_label(a.get("display_name", ""), a.get("email", "")))
		var lb := String(UserProfile.display_label(b.get("display_name", ""), b.get("email", "")))
		return la.naturalnocasecmp_to(lb) < 0
	)

	for child in lista.get_children():
		child.queue_free()

	if rows.is_empty():
		msg_estado.text = "Aún no hay usuarios."
		return

	msg_estado.text = "%d usuarios" % rows.size()
	for p in rows:
		lista.add_child(_crear_fila(p))


func _crear_fila(perfil: Dictionary) -> PanelContainer:
	var is_del    : bool   = bool(perfil.get("is_deleted", false))
	var is_adm    : bool   = bool(perfil.get("is_admin", false))
	var last_seen : String = perfil.get("last_seen", "") if perfil.get("last_seen", null) != null else ""
	var online    : bool   = UserProfile.is_online_from_iso(last_seen)

	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	margin.add_child(hbox)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var titulo_hbox := HBoxContainer.new()
	titulo_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(titulo_hbox)

	var dot := Label.new()
	dot.text = "●"
	dot.modulate = COLOR_ONLINE if online else COLOR_OFFLINE
	titulo_hbox.add_child(dot)

	var lbl_nombre := Label.new()
	lbl_nombre.text = UserProfile.display_label(perfil.get("display_name", ""), perfil.get("email", ""))
	lbl_nombre.add_theme_font_size_override("font_size", 26)
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre.clip_text = true
	titulo_hbox.add_child(lbl_nombre)

	if is_adm:
		var tag_adm := Label.new()
		tag_adm.text = "[admin]"
		tag_adm.add_theme_font_size_override("font_size", 16)
		titulo_hbox.add_child(tag_adm)

	if is_del:
		var tag_del := Label.new()
		tag_del.text = "(Eliminado)"
		tag_del.add_theme_font_size_override("font_size", 16)
		titulo_hbox.add_child(tag_del)

	var email_str : String = String(perfil.get("email", ""))
	if email_str != "" and email_str != lbl_nombre.text:
		var lbl_email := Label.new()
		lbl_email.text = email_str
		lbl_email.add_theme_font_size_override("font_size", 18)
		lbl_email.modulate = Color(1, 1, 1, 0.7)
		vbox.add_child(lbl_email)

	var lbl_meta := Label.new()
	lbl_meta.text = "última conexión: " + UserProfile.format_relative_time(last_seen)
	lbl_meta.add_theme_font_size_override("font_size", 16)
	lbl_meta.modulate = Color(1, 1, 1, 0.55)
	vbox.add_child(lbl_meta)

	var botones := VBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	hbox.add_child(botones)

	var btn_editar := Button.new()
	btn_editar.text = "Editar"
	btn_editar.pressed.connect(_on_editar_pressed.bind(perfil))
	botones.add_child(btn_editar)

	var btn_borrar := Button.new()
	btn_borrar.text = "Reactivar" if is_del else "Eliminar"
	btn_borrar.pressed.connect(_on_borrar_pressed.bind(perfil))
	botones.add_child(btn_borrar)

	if is_del:
		panel.modulate = Color(1, 1, 1, 0.5)

	return panel


# ─────────────────────────────────────────────
# Acciones
# ─────────────────────────────────────────────

func _on_editar_pressed(perfil: Dictionary) -> void:
	GameState.user_form_mode = "edit"
	GameState.user_form_data = perfil
	get_tree().change_scene_to_file(USER_FORM_PATH)


func _on_borrar_pressed(perfil: Dictionary) -> void:
	_pending_delete_uid = String(perfil.get("user_id", ""))
	var nombre := UserProfile.display_label(perfil.get("display_name", ""), perfil.get("email", ""))
	var is_del := bool(perfil.get("is_deleted", false))
	if is_del:
		var ok = await SupabaseClient.update_row("profiles", "user_id=eq.%s" % _pending_delete_uid, {"is_deleted": false})
		_pending_delete_uid = ""
		if not ok:
			_mostrar_info("Error", "No se pudo reactivar.")
			return
		await _refrescar()
		return
	_confirm_dialog.dialog_text = "¿Marcar a %s como eliminado?\n\nSu cuenta seguirá existiendo pero quedará oculta/etiquetada en las listas." % nombre
	_confirm_dialog.popup_centered()


func _on_confirm_eliminar() -> void:
	if _pending_delete_uid == "":
		return
	var uid := _pending_delete_uid
	_pending_delete_uid = ""
	var ok = await SupabaseClient.update_row("profiles", "user_id=eq.%s" % uid, {"is_deleted": true})
	if not ok:
		_mostrar_info("Error", "No se pudo marcar como eliminado.")
		return
	await _refrescar()


func _mostrar_info(titulo: String, mensaje: String) -> void:
	_info_dialog.title = titulo
	_info_dialog.dialog_text = mensaje
	_info_dialog.popup_centered()
