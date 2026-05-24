extends CanvasLayer

@onready var lista       : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/Lista
@onready var btn_volver  : Button        = $MarginContainer/Panel/MarginContainer/VBoxContainer/Volver
@onready var msg_estado  : Label         = $MarginContainer/Panel/MarginContainer/VBoxContainer/Estado

const CONFIG_PATH : String = "res://Escenas/Config.tscn"

const ANIMALES := {
	"fox":     "fox_progress",
	"owl":     "owl_progress",
	"dolphin": "dolphin_progress",
	"raven":   "raven_progress",
}

# Total de niveles por animal (tutorial + 10).
const TOTAL_LEVELS    : int = 11
const MAX_STARS_LEVEL : int = 3

const COLOR_ONLINE  : Color = Color(0.30, 0.85, 0.40)
const COLOR_OFFLINE : Color = Color(0.55, 0.55, 0.55)

func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)

	# Guard: solo administradores.
	if not UserProfile.is_admin:
		msg_estado.text = "Acceso restringido. Volviendo..."
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file(CONFIG_PATH)
		return

	msg_estado.text = "Cargando progreso de usuarios..."
	await _cargar()

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(CONFIG_PATH)

func _cargar() -> void:
	# datos[user_id][animal_id] = {done, stars, best_time}
	var datos : Dictionary = {}

	for animal_id in ANIMALES.keys():
		var table : String = ANIMALES[animal_id]
		var rows = await SupabaseClient.get_rows(table, "")
		for row in rows:
			var uid : String = row.get("user_id", "")
			if uid == "":
				continue
			if not datos.has(uid):
				datos[uid] = {}
			if not datos[uid].has(animal_id):
				datos[uid][animal_id] = {"done": 0, "stars": 0, "best_time": 0.0}

			var bucket = datos[uid][animal_id]
			if String(row.get("state", "")) == "done":
				bucket["done"] += 1
			bucket["stars"] += int(row.get("stars", 0))
			var bt: float = float(row.get("best_time", 0.0))
			if bt > 0.0 and (bucket["best_time"] == 0.0 or bt < bucket["best_time"]):
				bucket["best_time"] = bt

	# Perfiles (incluso los que no han jugado)
	var perfiles : Dictionary = {}
	var profiles = await SupabaseClient.get_rows("profiles", "")
	for p in profiles:
		var uid : String = p.get("user_id", "")
		if uid != "":
			perfiles[uid] = p

	# Unión de uids (con o sin progreso)
	var todos_uids : Dictionary = {}
	for uid in datos.keys():
		todos_uids[uid] = true
	for uid in perfiles.keys():
		todos_uids[uid] = true

	for child in lista.get_children():
		child.queue_free()

	if todos_uids.is_empty():
		msg_estado.text = "No hay usuarios registrados todavía."
		return

	msg_estado.text = "%d usuarios" % todos_uids.size()

	# Ordenar: vivos por estrellas totales desc, eliminados al final
	var uids : Array = todos_uids.keys()
	uids.sort_custom(func(a, b):
		var dela := bool(perfiles.get(a, {}).get("is_deleted", false))
		var delb := bool(perfiles.get(b, {}).get("is_deleted", false))
		if dela != delb:
			return not dela
		return _total_estrellas(datos.get(a, {})) > _total_estrellas(datos.get(b, {}))
	)

	for uid in uids:
		lista.add_child(_crear_bloque_usuario(uid, perfiles.get(uid, {}), datos.get(uid, {})))

func _total_estrellas(bloque: Dictionary) -> int:
	var total := 0
	for animal_id in bloque.keys():
		total += int(bloque[animal_id]["stars"])
	return total

func _crear_bloque_usuario(uid: String, perfil: Dictionary, bloque: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)

	# Cabecera: dot online + nombre + tag eliminado
	var last_seen : String = perfil.get("last_seen", "") if perfil.get("last_seen", null) != null else ""
	var is_del    : bool   = bool(perfil.get("is_deleted", false))
	var online    : bool   = UserProfile.is_online_from_iso(last_seen)

	var hbox_titulo := HBoxContainer.new()
	hbox_titulo.add_theme_constant_override("separation", 10)
	vbox.add_child(hbox_titulo)

	var dot := Label.new()
	dot.text = "●"
	dot.modulate = COLOR_ONLINE if online else COLOR_OFFLINE
	hbox_titulo.add_child(dot)

	var lbl_nombre := Label.new()
	lbl_nombre.text = UserProfile.display_label(perfil.get("display_name", ""), perfil.get("email", ""))
	lbl_nombre.add_theme_font_size_override("font_size", 28)
	lbl_nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_titulo.add_child(lbl_nombre)

	var lbl_estado := Label.new()
	lbl_estado.text = "(Eliminado)" if is_del else "(Activo)"
	lbl_estado.add_theme_font_size_override("font_size", 18)
	hbox_titulo.add_child(lbl_estado)

	# Email (si distinto del nombre)
	var email_str : String = String(perfil.get("email", ""))
	if email_str != "" and email_str != lbl_nombre.text:
		var lbl_email := Label.new()
		lbl_email.text = email_str
		lbl_email.add_theme_font_size_override("font_size", 18)
		lbl_email.modulate = Color(1, 1, 1, 0.7)
		vbox.add_child(lbl_email)

	# UID + última conexión
	var lbl_meta := Label.new()
	lbl_meta.text = "id %s · última conexión: %s" % [
		uid.substr(0, 8) + "…",
		UserProfile.format_relative_time(last_seen),
	]
	lbl_meta.add_theme_font_size_override("font_size", 16)
	lbl_meta.modulate = Color(1, 1, 1, 0.55)
	vbox.add_child(lbl_meta)

	# Filas por animal
	for animal_id in ANIMALES.keys():
		var b = bloque.get(animal_id, {"done": 0, "stars": 0, "best_time": 0.0})
		var fila := Label.new()
		fila.text = "%s · niveles %d/%d · ★ %d/%d · mejor %s" % [
			animal_id.capitalize(),
			b["done"], TOTAL_LEVELS,
			b["stars"], TOTAL_LEVELS * MAX_STARS_LEVEL,
			_formatear_tiempo(b["best_time"]),
		]
		vbox.add_child(fila)

	if is_del:
		panel.modulate = Color(1, 1, 1, 0.45)

	return panel

func _formatear_tiempo(seg: float) -> String:
	if seg <= 0.0:
		return "—"
	var m := int(seg) / 60
	var s := int(seg) % 60
	return "%d:%02d" % [m, s]
