# SupabaseClient.gd
# Autoload singleton — añádelo en Project > Project Settings > Autoload
# Nombre del Autoload: SupabaseClient
extends Node
 
# ─── CONFIGURACIÓN — rellena con tus datos ───────────────────────────────────
const SUPABASE_URL  = "https://bsiocvjcdfjkpwpsdvdl.supabase.co"
const SUPABASE_ANON = "sb_secret_WRnKvqKcbfgYgcHI5SCwyg_vMfkgbYx"
# ─────────────────────────────────────────────────────────────────────────────
 
var _headers = [
	"Content-Type: application/json",
	"apikey: %s" % SUPABASE_ANON,
	"Authorization: Bearer %s" % SUPABASE_ANON,
]
 
# ─────────────────────────────────────────────
# GET — lee filas de una tabla
# Devuelve la respuesta como Array o null si hay error
# ─────────────────────────────────────────────
 
func get_rows(table: String, filters: String = "") -> Array:
	var url = "%s/rest/v1/%s" % [SUPABASE_URL, table]
	if filters != "":
		url += "?" + filters
 
	var http = HTTPRequest.new()
	add_child(http)
 
	var err = http.request(url, _headers, HTTPClient.METHOD_GET)
	if err != OK:
		push_error("SupabaseClient: GET error %s" % err)
		http.queue_free()
		return []
 
	var result = await http.request_completed
	http.queue_free()
 
	var body = result[3].get_string_from_utf8()
	var parsed = JSON.parse_string(body)
	if parsed is Array:
		return parsed
	return []
 
# ─────────────────────────────────────────────
# UPSERT — inserta o actualiza una fila
# ─────────────────────────────────────────────
 
func upsert(table: String, data: Dictionary, conflict_key: String = "user_id,level_id") -> bool:
	var url = "%s/rest/v1/%s?on_conflict=%s" % [SUPABASE_URL, table, conflict_key]

	var headers = _headers.duplicate()
	headers.append("Prefer: return=representation,resolution=merge-duplicates")

	var body = JSON.stringify([data])

	var http = HTTPRequest.new()
	add_child(http)

	var err = http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		push_error("SupabaseClient: UPSERT error %s" % err)
		http.queue_free()
		return false

	var result = await http.request_completed
	http.queue_free()

	var code = result[1]
	return code == 200 or code == 201

# ─────────────────────────────────────────────
# UPDATE — actualiza filas que cumplen el filtro
# filter: cadena PostgREST sin "?" inicial (ej: "user_id=eq.X")
# ─────────────────────────────────────────────

func update_row(table: String, filter: String, data: Dictionary) -> bool:
	var url = "%s/rest/v1/%s?%s" % [SUPABASE_URL, table, filter]
	var http = HTTPRequest.new()
	add_child(http)

	var err = http.request(url, _headers, HTTPClient.METHOD_PATCH, JSON.stringify(data))
	if err != OK:
		push_error("SupabaseClient: PATCH error %s" % err)
		http.queue_free()
		return false

	var result = await http.request_completed
	http.queue_free()

	var code = result[1]
	return code == 200 or code == 204

# ─────────────────────────────────────────────
# ADMIN — crea un usuario via Admin API.
# Requiere que SUPABASE_ANON sea una service_role key (lo es: sb_secret_*).
# Devuelve el user_id del nuevo usuario, o "" en error.
# ─────────────────────────────────────────────

func admin_create_user(email: String, password: String, nombre: String, _is_admin: bool = false) -> String:
	var url = "%s/auth/v1/admin/users" % SUPABASE_URL

	var payload = {
		"email": email,
		"password": password,
		"email_confirm": true,
		"user_metadata": {"nombre": nombre},
	}

	var http = HTTPRequest.new()
	add_child(http)

	var err = http.request(url, _headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		push_error("SupabaseClient: admin_create_user request error %s" % err)
		http.queue_free()
		return ""

	var result = await http.request_completed
	http.queue_free()

	var code = result[1]
	var body = result[3].get_string_from_utf8()
	if code != 200 and code != 201:
		push_error("SupabaseClient: admin_create_user HTTP %d — %s" % [code, body])
		return ""

	var parsed = JSON.parse_string(body)
	if parsed is Dictionary:
		return String(parsed.get("id", ""))
	return ""

