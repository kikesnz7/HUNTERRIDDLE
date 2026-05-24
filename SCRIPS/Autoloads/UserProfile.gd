# UserProfile.gd
# Autoload singleton — Project > Project Settings > Autoload > "UserProfile"
#
# Mantiene en memoria los datos del perfil del usuario autenticado y expone
# helpers estáticos usados por las pantallas de ranking/administración.
#
# La tabla "profiles" en Supabase debe existir con este esquema:
#
#   CREATE TABLE profiles (
#     user_id      text PRIMARY KEY,
#     email        text NOT NULL,
#     display_name text,
#     is_admin     boolean NOT NULL DEFAULT false,
#     is_deleted   boolean NOT NULL DEFAULT false,
#     last_seen    timestamptz,
#     created_at   timestamptz NOT NULL DEFAULT now()
#   );
extends Node

signal profile_loaded

const ONLINE_THRESHOLD_SECONDS : int = 300  # 5 minutos

var email        : String = ""
var display_name : String = ""
var is_admin     : bool   = false
var is_deleted   : bool   = false
var last_seen    : String = ""   # ISO 8601 UTC


# Llamar tras autenticar (login o register).
# - Upsert con user_id + email + last_seen (+ display_name si se pasa no vacío).
#   No se envían is_admin ni is_deleted, así que el merge-duplicates de PostgREST
#   preserva sus valores existentes.
# - Releer la fila completa para sincronizar los flags reales desde la BD.
func load_profile(uid: String, user_email: String, name: String = "") -> void:
	if uid == "":
		emit_signal("profile_loaded")
		return

	email        = user_email
	display_name = name

	var row : Dictionary = {
		"user_id":   uid,
		"email":     user_email,
		"last_seen": now_utc_iso(),
	}
	if name.strip_edges() != "":
		row["display_name"] = name

	await SupabaseClient.upsert("profiles", row, "user_id")

	# Releer para conocer is_admin / is_deleted / display_name reales.
	var rows = await SupabaseClient.get_rows("profiles", "user_id=eq.%s" % uid)
	if rows.size() > 0:
		var p = rows[0]
		email        = p.get("email", user_email)
		display_name = p.get("display_name", name) if p.get("display_name", null) != null else name
		is_admin     = bool(p.get("is_admin", false))
		is_deleted   = bool(p.get("is_deleted", false))
		last_seen    = p.get("last_seen", "") if p.get("last_seen", null) != null else ""
	else:
		is_admin   = false
		is_deleted = false
		last_seen  = ""

	emit_signal("profile_loaded")


func clear() -> void:
	email        = ""
	display_name = ""
	is_admin     = false
	is_deleted   = false
	last_seen    = ""


# ─────────────────────────────────────────────
# HELPERS ESTÁTICOS (reutilizados por las pantallas)
# ─────────────────────────────────────────────

# Devuelve la hora UTC actual en formato ISO 8601 (lo que acepta timestamptz).
static func now_utc_iso() -> String:
	return Time.get_datetime_string_from_system(true) + "Z"


# "Nombre" → "Email" → "Usuario sin nombre".
static func display_label(name: String, mail: String) -> String:
	if name != null and String(name).strip_edges() != "":
		return String(name)
	if mail != null and String(mail).strip_edges() != "":
		return String(mail)
	return "Usuario sin nombre"


# Considera online si last_seen fue actualizado hace menos de ONLINE_THRESHOLD_SECONDS.
static func is_online_from_iso(last_seen_iso: String) -> bool:
	var ts := _parse_iso_to_unix(last_seen_iso)
	if ts == 0:
		return false
	var now := int(Time.get_unix_time_from_system())
	return (now - ts) <= ONLINE_THRESHOLD_SECONDS


# "hace 5 min" / "hace 2 h" / "hace 3 d" / "2026-05-24".
static func format_relative_time(last_seen_iso: String) -> String:
	if last_seen_iso == "":
		return "nunca"
	var ts := _parse_iso_to_unix(last_seen_iso)
	if ts == 0:
		return "—"
	var diff := int(Time.get_unix_time_from_system()) - ts
	if diff < 0:
		diff = 0
	if diff < 60:
		return "hace segundos"
	if diff < 3600:
		return "hace %d min" % (diff / 60)
	if diff < 86400:
		return "hace %d h" % (diff / 3600)
	if diff < 7 * 86400:
		return "hace %d d" % (diff / 86400)
	return last_seen_iso.substr(0, 10)


# Parser tolerante: extrae los primeros 19 chars (YYYY-MM-DDTHH:MM:SS)
# y los interpreta como UTC. Funciona con "...Z" y "...+00:00" y con o sin microsegundos.
static func _parse_iso_to_unix(s: String) -> int:
	if s == null or String(s).length() < 19:
		return 0
	var clean := String(s).substr(0, 19)
	var ts := int(Time.get_unix_time_from_datetime_string(clean))
	return ts
