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
