extends CanvasLayer

@onready var lista       : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/Lista
@onready var btn_volver  : Button        = $MarginContainer/Panel/MarginContainer/VBoxContainer/Volver
@onready var msg_estado  : Label         = $MarginContainer/Panel/MarginContainer/VBoxContainer/Estado

const CONFIG_PATH : String = "res://Escenas/Config.tscn"

const ANIMAL_TABLES := [
	"fox_progress",
	"owl_progress",
	"dolphin_progress",
	"raven_progress",
]

const COLOR_ONLINE  : Color = Color(0.30, 0.85, 0.40)  # verde
const COLOR_OFFLINE : Color = Color(0.55, 0.55, 0.55)  # gris

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)
	msg_estado.text = "Cargando ranking..."
	await _cargar_ranking()

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(CONFIG_PATH)

func _cargar_ranking() -> void:
	# 1. Suma estrellas por user_id a través de las 4 tablas de progreso.
	var stars_por_usuario : Dictionary = {}
	for table in ANIMAL_TABLES:
		var rows = await SupabaseClient.get_rows(table, "")
		for row in rows:
			var uid: String = row.get("user_id", "")
			if uid == "":
				continue
			var s: int = int(row.get("stars", 0))
			stars_por_usuario[uid] = int(stars_por_usuario.get(uid, 0)) + s

	# 2. Carga el perfil completo desde profiles.
	var perfiles : Dictionary = {}
	var profiles = await SupabaseClient.get_rows("profiles", "")
	for p in profiles:
		var uid: String = p.get("user_id", "")
		if uid != "":
			perfiles[uid] = p

	# 3. Construye la lista. Incluye también usuarios que tienen perfil pero
	#    sin progreso (aparecerán con 0 estrellas), porque puede ser útil
	#    ver quién está registrado aunque no haya jugado.
	var todos_uids : Dictionary = {}
	for uid in stars_por_usuario.keys():
		todos_uids[uid] = true
	for uid in perfiles.keys():
		todos_uids[uid] = true

	var lista_ord : Array = []
	for uid in todos_uids.keys():
		var p : Dictionary = perfiles.get(uid, {})
		lista_ord.append({
			"uid":          uid,
			"display_name": p.get("display_name", ""),
			"email":        p.get("email", ""),
			"stars":        int(stars_por_usuario.get(uid, 0)),
			"is_deleted":   bool(p.get("is_deleted", false)),
			"last_seen":    p.get("last_seen", "") if p.get("last_seen", null) != null else "",
		})

	# 4. Orden: vivos primero (por estrellas desc), eliminados al final.
	lista_ord.sort_custom(func(a, b):
		if a["is_deleted"] != b["is_deleted"]:
			return not a["is_deleted"]
		return a["stars"] > b["stars"]
	)

	# 5. Pintar
	for child in lista.get_children():
		child.queue_free()

	if lista_ord.is_empty():
		msg_estado.text = "Aún no hay datos."
		return

	msg_estado.text = "Top jugadores por estrellas"
	var rank := 0
	for entry in lista_ord:
		# El ranking numérico solo cuenta para vivos; los eliminados van sin número.
		if not entry["is_deleted"]:
			rank += 1
			lista.add_child(_crear_fila(rank, entry))
		else:
			lista.add_child(_crear_fila(-1, entry))

func _crear_fila(rank: int, entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 18)
	panel.add_child(hbox)

	# Columna rank
	var lbl_rank := Label.new()
	lbl_rank.text = "#%d" % rank if rank > 0 else "—"
	lbl_rank.custom_minimum_size = Vector2(80, 0)
	hbox.add_child(lbl_rank)

	# Columna nombre + email + estado
	var vbox_nombre := VBoxContainer.new()
	vbox_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_nombre.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox_nombre)

	# Línea 1: nombre + dot online
	var hbox_titulo := HBoxContainer.new()
	hbox_titulo.add_theme_constant_override("separation", 10)
	vbox_nombre.add_child(hbox_titulo)

	var online := UserProfile.is_online_from_iso(entry["last_seen"])
	var dot := Label.new()
	dot.text = "●"
	dot.modulate = COLOR_ONLINE if online else COLOR_OFFLINE
	hbox_titulo.add_child(dot)

	var lbl_nombre := Label.new()
	lbl_nombre.text = UserProfile.display_label(entry["display_name"], entry["email"])
	lbl_nombre.add_theme_font_size_override("font_size", 28)
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_nombre.clip_text = true
	hbox_titulo.add_child(lbl_nombre)

	if entry["is_deleted"]:
		var tag := Label.new()
		tag.text = "(Eliminado)"
		tag.add_theme_font_size_override("font_size", 18)
		hbox_titulo.add_child(tag)

	# Línea 2: última conexión
	var lbl_visto := Label.new()
	lbl_visto.text = "Última conexión: " + UserProfile.format_relative_time(entry["last_seen"])
	lbl_visto.add_theme_font_size_override("font_size", 18)
	lbl_visto.modulate = Color(1, 1, 1, 0.65)
	vbox_nombre.add_child(lbl_visto)

	# Columna estrellas
	var lbl_stars := Label.new()
	lbl_stars.text = "★ %d" % int(entry["stars"])
	lbl_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl_stars.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl_stars)

	if entry["is_deleted"]:
		panel.modulate = Color(1, 1, 1, 0.45)

	return panel
