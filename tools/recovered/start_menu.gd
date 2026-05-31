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

@onready var _logo_sprite : Node = find_child("Hunterriddle", true, false)

var _color_buttons : Array = []

func _ready() -> void:
	AudioManager.play_menu_music()
	_apply_saved_volume()
	_load_beam_color()
	_center_logo()
	get_viewport().size_changed.connect(_center_logo)
	Supabase.auth_success.connect(_on_auth_success)
	Supabase.auth_error.connect(_on_auth_error)
	btn_entrar.pressed.connect(_on_enter_btn_pressed)
	#btn_offline.pressed.connect(_on_offline_pressed)
	btn_salir.pressed.connect(_on_exit_pressed)
	btn_iniciar.pressed.connect(_on_iniciar_btn_pressed)
	btn_config.pressed.connect(_on_config_btn_pressed)
	_setup_beam_picker()

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

func _center_logo() -> void:
	if not _logo_sprite:
		return
	var vp := get_viewport().get_visible_rect().size
	_logo_sprite.position = vp / 2.0

# ── Selector de color del haz ────────────────────────────────────────────────

func _read_cached_score() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return 0
	return int(cfg.get_value("beam", "cached_total_score", 0))

func _load_beam_color() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	var key : String = cfg.get_value("beam", "selected_color", "default")
	for opt in GameState.BEAM_OPTIONS:
		if opt["key"] == key:
			GameState.beam_color = opt["color"]
			return

func _setup_beam_picker() -> void:
	var vbox_root := find_child("VBoxContainer", false, false)
	if not vbox_root:
		return

	var cached_score := _read_cached_score()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 4)

	var col_vbox := VBoxContainer.new()
	col_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(col_vbox)

	var lbl := Label.new()
	lbl.text = "Color del haz"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 16)
	col_vbox.add_child(lbl)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 14)
	col_vbox.add_child(hbox)

	_color_buttons.clear()
	for opt in GameState.BEAM_OPTIONS:
		var unlocked : bool = cached_score >= int(opt["pts"])
		var btn := _make_color_btn(opt, unlocked)
		hbox.add_child(btn)
		_color_buttons.append({"node": btn, "key": opt["key"]})

	vbox_root.add_child(margin)
	_refresh_color_selection()

func _make_color_btn(opt: Dictionary, unlocked: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(68, 68)

	var sb := StyleBoxFlat.new()
	sb.bg_color = (opt["color"] as Color).darkened(0.5) if not unlocked else opt["color"]
	sb.set_corner_radius_all(10)
	sb.content_margin_left   = 4
	sb.content_margin_right  = 4
	sb.content_margin_top    = 4
	sb.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", sb)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 2)
	panel.add_child(inner)

	var lbl_name := Label.new()
	lbl_name.text = opt["label"]
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 12)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	inner.add_child(lbl_name)

	if not unlocked:
		var lbl_pts := Label.new()
		lbl_pts.text = "%d pts" % int(opt["pts"])
		lbl_pts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_pts.add_theme_font_size_override("font_size", 10)
		lbl_pts.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		inner.add_child(lbl_pts)

	if unlocked:
		var key : String = opt["key"]
		var color : Color = opt["color"]
		panel.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:
				_select_beam_color(key, color)
		)

	return panel

func _select_beam_color(key: String, color: Color) -> void:
	GameState.beam_color = color
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("beam", "selected_color", key)
	cfg.save(SETTINGS_PATH)
	_refresh_color_selection()

func _refresh_color_selection() -> void:
	var selected_key : String = ""
	for opt in GameState.BEAM_OPTIONS:
		if opt["color"] == GameState.beam_color:
			selected_key = opt["key"]
			break
	for entry in _color_buttons:
		var panel := entry["node"] as PanelContainer
		var is_sel : bool = entry["key"] == selected_key
		var sb := panel.get_theme_stylebox("panel") as StyleBoxFlat
		if sb:
			sb.border_width_top    = 3 if is_sel else 0
			sb.border_width_bottom = 3 if is_sel else 0
			sb.border_width_left   = 3 if is_sel else 0
			sb.border_width_right  = 3 if is_sel else 0
			sb.border_color = Color.WHITE
