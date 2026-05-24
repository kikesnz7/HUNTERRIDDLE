# ProgressManager.gd
# Autoload singleton — Project > Project Settings > Autoload > "ProgressManager"
extends Node

signal level_unlocked(animal_id: String, level_id: String)
signal progress_saved
signal progress_loaded

# ─────────────────────────────────────────────
# CONFIGURACIÓN
# ─────────────────────────────────────────────

# Niveles que nunca pueden quedar bloqueados, sin importar el archivo guardado
const ALWAYS_UNLOCKED = ["level_1"]

const LEVEL_ORDER = {
	"fox":     ["tutorial", "level_1", "level_2", "level_3", "level_4", "level_5", "level_6", "level_7", "level_8", "level_9", "level_10"],
	"owl":     ["tutorial", "level_1", "level_2", "level_3", "level_4", "level_5", "level_6", "level_7", "level_8", "level_9", "level_10"],
	"dolphin": ["tutorial", "level_1", "level_2", "level_3", "level_4", "level_5", "level_6", "level_7", "level_8", "level_9", "level_10"],
	"raven":   ["tutorial", "level_1", "level_2", "level_3", "level_4", "level_5", "level_6", "level_7", "level_8", "level_9", "level_10"],
}

# Nombre de la tabla en Supabase por animal
const SUPABASE_TABLES = {
	"fox":     "fox_progress",
	"owl":     "owl_progress",
	"dolphin": "dolphin_progress",
	"raven":   "raven_progress",
}

var is_guest : bool   = false
var user_id  : String = ""   # se rellena al autenticar

# Progreso en memoria: _progress[animal_id][level_id] = {state, stars, best_time}
var _progress       : Dictionary = {}
# Animales cuyo progreso ya fue cargado desde Supabase/archivo en esta sesión
var _loaded_animals : Array      = []

# ─────────────────────────────────────────────
# INICIALIZACIÓN
# ─────────────────────────────────────────────

func _ready():
	_init_default_progress()

# Rellena _progress con el estado por defecto al arrancar la app.
# Solo se llama una vez; load_local / load_supabase lo sobreescribe después.
func _init_default_progress():
	for animal in LEVEL_ORDER.keys():
		_progress[animal] = {}
		var levels = LEVEL_ORDER[animal]
		for i in range(levels.size()):
			var lvl_id: String = levels[i]
			_progress[animal][lvl_id] = {
				"state":     "unlocked" if (i == 0 or lvl_id in ALWAYS_UNLOCKED) else "locked",
				"stars":     0,
				"best_time": 0.0
			}

# Limpia el estado en memoria al cambiar de usuario o iniciar sesión.
# Debe llamarse justo después de asignar user_id e is_guest.
func reset_for_new_session() -> void:
	_init_default_progress()
	_loaded_animals.clear()

# ─────────────────────────────────────────────
# HELPERS DE INTEGRIDAD — se aplican tras cualquier carga
# ─────────────────────────────────────────────

# Garantiza que si level_N está "done", level_N+1 esté al menos "unlocked".
# Esto hace que el estado "unlocked" sea DERIVADO del estado "done",
# en lugar de depender de que se haya guardado explícitamente en la BD.
func _derive_unlocked_from_done(animal_id: String):
	var order = LEVEL_ORDER.get(animal_id, [])
	for i in range(order.size() - 1):
		if _progress[animal_id][order[i]]["state"] == "done":
			var next_id = order[i + 1]
			if _progress[animal_id][next_id]["state"] == "locked":
				_progress[animal_id][next_id]["state"] = "unlocked"

# Garantiza que los niveles en ALWAYS_UNLOCKED nunca queden con state "locked".
func _apply_always_unlocked(animal_id: String):
	if not _progress.has(animal_id):
		return
	for lvl_id in ALWAYS_UNLOCKED:
		if _progress[animal_id].has(lvl_id):
			if _progress[animal_id][lvl_id]["state"] == "locked":
				_progress[animal_id][lvl_id]["state"] = "unlocked"

# ─────────────────────────────────────────────
# LECTURA
# ─────────────────────────────────────────────

func get_level_state(animal_id: String, level_id: String) -> String:
	if _progress.has(animal_id) and _progress[animal_id].has(level_id):
		return _progress[animal_id][level_id]["state"]
	return "locked"

func get_level_stars(animal_id: String, level_id: String) -> int:
	if _progress.has(animal_id) and _progress[animal_id].has(level_id):
		return _progress[animal_id][level_id]["stars"]
	return 0

func get_level_best_time(animal_id: String, level_id: String) -> float:
	if _progress.has(animal_id) and _progress[animal_id].has(level_id):
		return _progress[animal_id][level_id]["best_time"]
	return 0.0

func get_animal_progress(animal_id: String) -> Dictionary:
	if _progress.has(animal_id):
		return _progress[animal_id]
	return {}

# ─────────────────────────────────────────────
# COMPLETAR NIVEL — llamado desde PuzzleManager
# ─────────────────────────────────────────────

func complete_level(animal_id: String, level_id: String, stars: int, time: float):
	if not _progress.has(animal_id):
		return

	# 1. Actualiza el nivel completado en memoria
	var current = _progress[animal_id][level_id]
	current["state"] = "done"
	current["stars"] = max(current["stars"], stars)
	if current["best_time"] == 0.0 or time < current["best_time"]:
		current["best_time"] = time

	# 2. Desbloquea el nivel siguiente en memoria
	var next_id = _get_next_level(animal_id, level_id)
	if next_id != "":
		if _progress[animal_id][next_id]["state"] == "locked":
			_progress[animal_id][next_id]["state"] = "unlocked"
			emit_signal("level_unlocked", animal_id, next_id)

	# 3. Guarda localmente (SIEMPRE, para ambos modos).
	_save_local(animal_id)

	# 4. Sincroniza con Supabase para usuarios registrados.
	#    Solo guardamos el nivel completado ("done"); el estado "unlocked"
	#    del siguiente nivel se deriva automáticamente al cargar (ver _derive_unlocked_from_done).
	if not is_guest:
		await _save_supabase(animal_id, level_id)

func _get_next_level(animal_id: String, current_id: String) -> String:
	var order = LEVEL_ORDER.get(animal_id, [])
	var idx   = order.find(current_id)
	if idx == -1 or idx >= order.size() - 1:
		return ""
	return order[idx + 1]

# ─────────────────────────────────────────────
# PERSISTENCIA LOCAL
# ─────────────────────────────────────────────

# Serializa el progreso completo de un animal a disco.
func _save_local(animal_id: String):
	if is_guest or user_id == "":
		return
	var path = "user://progress_%s_%s.json" % [user_id, animal_id]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(_progress[animal_id]))
		file.close()
	emit_signal("progress_saved")

# Lee el archivo local y sobreescribe _progress[animal_id].
# Helper interno sin efectos secundarios (sin señales).
func _apply_local_file(animal_id: String):
	if user_id == "":
		return
	var path = "user://progress_%s_%s.json" % [user_id, animal_id]
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		_progress[animal_id] = parsed

# Carga el progreso desde archivo local y emite progress_loaded.
# En modo invitado NO lee el archivo — cada sesión sin cuenta empieza desde cero,
# evitando que se cargue progreso de un usuario registrado que jugó antes en el mismo dispositivo.
# Cuando is_guest=false se usa como fallback si Supabase falla.
func load_local(animal_id: String):
	if not is_guest:
		_apply_local_file(animal_id)
	_derive_unlocked_from_done(animal_id)
	_apply_always_unlocked(animal_id)
	if animal_id not in _loaded_animals:
		_loaded_animals.append(animal_id)
	emit_signal("progress_loaded")

# ─────────────────────────────────────────────
# PERSISTENCIA SUPABASE — usuario registrado
#
# Tabla requerida en Supabase (ejemplo para fox_progress):
#
# CREATE TABLE fox_progress (
#   id        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
#   user_id   text NOT NULL,
#   level_id  text NOT NULL,
#   state     text NOT NULL DEFAULT 'locked',
#   stars     int  NOT NULL DEFAULT 0,
#   best_time float NOT NULL DEFAULT 0,
#   UNIQUE(user_id, level_id)
# );
#
# Repite para owl_progress, dolphin_progress, raven_progress.
# ─────────────────────────────────────────────

func _save_supabase(animal_id: String, level_id: String):
	if user_id == "":
		push_error("ProgressManager: user_id vacío, no se puede guardar en Supabase")
		return

	var table = SUPABASE_TABLES.get(animal_id, "")
	if table == "":
		return

	var level_data = _progress[animal_id][level_id]
	var row = {
		"user_id":   user_id,
		"level_id":  level_id,
		"state":     level_data["state"],
		"stars":     level_data["stars"],
		"best_time": level_data["best_time"]
	}

	var ok = await SupabaseClient.upsert(table, row)
	if ok:
		emit_signal("progress_saved")
	else:
		push_error("ProgressManager: error guardando %s/%s en Supabase" % [animal_id, level_id])

func load_supabase(animal_id: String):
	if user_id == "":
		push_error("ProgressManager: user_id vacío, no se puede cargar de Supabase")
		emit_signal("progress_loaded")
		return

	var table = SUPABASE_TABLES.get(animal_id, "")
	if table == "":
		emit_signal("progress_loaded")
		return

	var filter = "user_id=eq.%s" % user_id
	var rows   = await SupabaseClient.get_rows(table, filter)

	if rows.is_empty():
		# Sin datos remotos (primera vez o fallo de red).
		# Usamos el archivo local como respaldo si existe.
		var local_path = "user://progress_%s_%s.json" % [user_id, animal_id]
		if FileAccess.file_exists(local_path):
			load_local(animal_id)   # emite progress_loaded
			return
		# Primera vez sin ningún dato: sube los defaults al servidor
		for level_id in _progress[animal_id].keys():
			_save_supabase(animal_id, level_id)
	else:
		# Aplica los datos de Supabase
		for row in rows:
			var level_id = row.get("level_id", "")
			if level_id == "" or not _progress[animal_id].has(level_id):
				continue
			_progress[animal_id][level_id] = {
				"state":     row.get("state",     "locked"),
				"stars":     row.get("stars",     0),
				"best_time": row.get("best_time", 0.0)
			}

		# CLAVE: reconstruye los estados "unlocked" a partir de los "done".
		# Esto garantiza que si level_N está "done" en Supabase, level_N+1
		# se muestra como "unlocked" aunque ese estado no se guardara
		# explícitamente en la base de datos.
		_derive_unlocked_from_done(animal_id)

	_apply_always_unlocked(animal_id)
	if animal_id not in _loaded_animals:
		_loaded_animals.append(animal_id)
	emit_signal("progress_loaded")

# ─────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────

# ─────────────────────────────────────────────
# GUARDADO A MITAD DE NIVEL — local, solo usuarios registrados
# ─────────────────────────────────────────────

func save_mid_level(animal_id: String, level_id: String, state: Dictionary) -> void:
	if is_guest or user_id == "":
		return
	var path = "user://mid_%s_%s_%s.json" % [user_id, animal_id, level_id]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(state))
		file.close()

func load_mid_level(animal_id: String, level_id: String) -> Dictionary:
	if is_guest or user_id == "":
		return {}
	var path = "user://mid_%s_%s_%s.json" % [user_id, animal_id, level_id]
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}

func clear_mid_level(animal_id: String, level_id: String) -> void:
	if user_id == "":
		return
	var path = "user://mid_%s_%s_%s.json" % [user_id, animal_id, level_id]
	if FileAccess.file_exists(path):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("mid_%s_%s_%s.json" % [user_id, animal_id, level_id])

# ─────────────────────────────────────────────
# UTILIDADES
# ─────────────────────────────────────────────

func reset_animal(animal_id: String):
	var levels = LEVEL_ORDER.get(animal_id, [])
	for i in range(levels.size()):
		_progress[animal_id][levels[i]] = {
			"state":     "unlocked" if i == 0 else "locked",
			"stars":     0,
			"best_time": 0.0
		}
	if is_guest:
		_save_local(animal_id)
	else:
		for level_id in _progress[animal_id].keys():
			_save_supabase(animal_id, level_id)
