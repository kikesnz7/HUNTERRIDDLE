@tool
extends Node

const ENVIRONMENT_VARIABLES : String = "supabase/config"

var auth : SupabaseAuth 
var database : SupabaseDatabase
var realtime : SupabaseRealtime
var storage : SupabaseStorage
const URL = "https://bsiocvjcdfjkpwpsdvdl.supabase.co"
const API_KEY = "sb_secret_WRnKvqKcbfgYgcHI5SCwyg_vMfkgbYx"
var debug: bool = false

var config : Dictionary = {
	"supabaseUrl": "https://bsiocvjcdfjkpwpsdvdl.supabase.co/rest/v1/",
	"supabaseKey": "sb_publishable_Te59-oJ03JfF65wXFkjFSA_yRTphcw4
"
}

var header : PackedStringArray = [
	"Content-Type: application/json",
	"Accept: application/json"
]
signal auth_success(user_data)
signal auth_error(error_message)
# Sesión activa
var access_token: String = ""
var current_user: Dictionary = {}

func sign_up(email: String, password: String, nombre: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_signup_completed.bind(http))
	var body = JSON.stringify({
	"email": email,
	"password": password,
	"data": {"nombre": nombre}  # <-- va a raw_user_meta_data
	})
	var headers = [
	"Content-Type: application/json",
	"apikey: " + API_KEY
	]
	http.request(URL + "/auth/v1/signup", headers, HTTPClient.METHOD_POST, body)
func sign_in(email: String, password: String) -> void:
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_signin_completed.bind(http))
	var body = JSON.stringify({"email": email, "password": password})
	var headers = [
	"Content-Type: application/json",
	"apikey: " + API_KEY
	]
	# ✅ Sin /rest/v1, solo /auth/v1/token
	http.request(URL + "/auth/v1/token?grant_type=password", headers, HTTPClient.METHOD_POST, body)

func _on_signup_completed(result, response_code, _headers, body, http: HTTPRequest) -> void:
	http.queue_free()
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()

	if response_code == 200:
		emit_signal("auth_success", data)
	else:
		var msg = data.get("msg", data.get("message", "Error al registrar"))
		emit_signal("auth_error", msg)


func _on_signin_completed(result, response_code, _headers, body, http: HTTPRequest) -> void:
	http.queue_free()
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()

	if response_code == 200:
		emit_signal("auth_success", data)
	else:
		var msg = data.get("error_description", data.get("msg", "Error al iniciar sesión"))
		emit_signal("auth_error", msg)
func _ready() -> void:
	load_config()
	load_nodes()

# Load all config settings from ProjectSettings
func load_config() -> void:
	if config.supabaseKey != "" and config.supabaseUrl != "":
		pass
	else:    
		var env = ConfigFile.new()
		var err = env.load("res://addons/supabase/.env")
		if err == OK:
			for key in config.keys(): 
				var value : String = env.get_value(ENVIRONMENT_VARIABLES, key, "")
				if value == "":
					printerr("%s has not a valid value." % key)
				else:
					config[key] = value
		else:
			printerr("Unable to read .env file at path 'res://.env'")
	header.append("apikey: %s"%[config.supabaseKey])

func load_nodes() -> void:
	auth = SupabaseAuth.new(config, header)
	database = SupabaseDatabase.new(config, header)
	realtime = SupabaseRealtime.new(config)
	storage = SupabaseStorage.new(config)
	add_child(auth)
	add_child(database)
	add_child(realtime)
	add_child(storage)

func set_debug(debugging: bool) -> void:
	debug = debugging

func _print_debug(msg: String) -> void:
	if debug: print_debug(msg)
func _save_session(data: Dictionary) -> void:
	access_token = data.get("access_token", "")
	current_user = data.get("user", {})


# ─────────────────────────────────────────────
# GOOGLE OAUTH — flujo PKCE para desktop
# ─────────────────────────────────────────────

var _google_auth_in_progress := false

func sign_in_with_google() -> void:
	if _google_auth_in_progress:
		return
	if OS.get_name() in ["Android", "iOS"]:
		emit_signal("auth_error", "La autenticación con Google no está disponible en móvil todavía")
		return

	_google_auth_in_progress = true

	var verifier  : String = _pkce_generate_verifier()
	var challenge : String = _pkce_generate_challenge(verifier)
	var redirect  : String = "http://localhost:8091"

	var auth_url : String = "%s/auth/v1/authorize?provider=google&redirect_to=%s&code_challenge=%s&code_challenge_method=S256" % [
		URL,
		redirect.uri_encode(),
		challenge
	]

	var server := TCPServer.new()
	if server.listen(8091) != OK:
		_google_auth_in_progress = false
		emit_signal("auth_error", "Puerto 8091 ocupado. Cierra otras aplicaciones e inténtalo de nuevo.")
		return

	OS.shell_open(auth_url)

	var code : String = await _pkce_wait_for_code(server)
	_google_auth_in_progress = false

	if code == "":
		emit_signal("auth_error", "No se recibió respuesta de Google (tiempo agotado).")
		return

	_pkce_exchange_code(code, verifier)


func _pkce_generate_verifier() -> String:
	var crypto := Crypto.new()
	var raw    := crypto.generate_random_bytes(96)
	var b64    := Marshalls.raw_to_base64(raw)
	return b64.replace("+", "-").replace("/", "_").replace("=", "")


func _pkce_generate_challenge(verifier: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(verifier.to_utf8_buffer())
	var b64 := Marshalls.raw_to_base64(ctx.finish())
	return b64.replace("+", "-").replace("/", "_").replace("=", "")


func _pkce_wait_for_code(server: TCPServer) -> String:
	var elapsed := 0.0
	var timeout := 120.0
	while elapsed < timeout:
		if server.is_connection_available():
			var peer := server.take_connection()
			await get_tree().create_timer(0.2).timeout
			var bytes := peer.get_available_bytes()
			if bytes > 0:
				var raw  := peer.get_utf8_string(bytes)
				var code := _pkce_parse_code(raw)
				_pkce_send_success_page(peer)
				server.stop()
				return code
		await get_tree().create_timer(0.5).timeout
		elapsed += 0.5
	server.stop()
	return ""


func _pkce_parse_code(request: String) -> String:
	var parts := request.split("\r\n")[0].split(" ")
	if parts.size() < 2:
		return ""
	var q := parts[1].find("?")
	if q == -1:
		return ""
	for param in parts[1].substr(q + 1).split("&"):
		var eq := param.find("=")
		if eq != -1 and param.substr(0, eq) == "code":
			return param.substr(eq + 1).uri_decode()
	return ""


func _pkce_send_success_page(peer: StreamPeerTCP) -> void:
	var html := (
		"<html><meta charset='utf-8'>"
		+ "<body style='font-family:sans-serif;text-align:center;padding:60px;background:#f0fdf4'>"
		+ "<h2 style='color:#166534'>Autenticacion completada</h2>"
		+ "<p>Puedes cerrar esta ventana y volver al juego.</p>"
		+ "</body></html>"
	)
	var response := (
		"HTTP/1.1 200 OK\r\n"
		+ "Content-Type: text/html; charset=utf-8\r\n"
		+ "Content-Length: %d\r\n"
		+ "Connection: close\r\n\r\n%s"
	) % [html.length(), html]
	peer.put_data(response.to_utf8_buffer())


func _pkce_exchange_code(code: String, verifier: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_google_exchange_completed.bind(http))
	var body := JSON.stringify({"auth_code": code, "code_verifier": verifier})
	var headers := [
		"Content-Type: application/json",
		"apikey: " + API_KEY
	]
	var err := http.request(URL + "/auth/v1/token?grant_type=pkce", headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		emit_signal("auth_error", "Error interno al iniciar intercambio OAuth.")


func _on_google_exchange_completed(_result: int, http_code: int, _hdr: PackedStringArray, body: PackedByteArray, http: HTTPRequest) -> void:
	http.queue_free()
	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()
	if http_code == 200 and data is Dictionary:
		_save_session(data)
		emit_signal("auth_success", data)
	else:
		var msg := "Error en autenticación con Google."
		if data is Dictionary:
			msg = data.get("error_description", data.get("msg", data.get("error", msg)))
		emit_signal("auth_error", msg)
