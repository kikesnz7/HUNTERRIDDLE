extends Control

# --- REFERENCIAS A LOS NODOS DE LA UI ---
# (Ajusta estas rutas según cómo tengas organizados los nodos en tu escena)
@onready var email_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/CorreoInpt
@onready var password_input: LineEdit = $PanelContainer/MarginContainer/VBoxContainer/ContraInpt
@onready var btn_login: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button
@onready var btn_offline: Button =$PanelContainer/MarginContainer/VBoxContainer/MarginContainer2/HBoxContainer/Button2
@onready var btn_exit: Button = $PanelContainer/MarginContainer/VBoxContainer/MarginContainer/Button
@onready var Msg_corr: Label = $PanelContainer/MarginContainer/VBoxContainer/ValCorr
@onready var Msg_cont: Label = $PanelContainer/MarginContainer/VBoxContainer/ValContras
@onready var Msg_sess: Label = $PanelContainer/MarginContainer/VBoxContainer/ValSesion

# Variable local para saber si está logeado (recomendado pasarla a un Autoload global)
var is_logged_in: bool = false

# Ruta de la escena a la que vas a redirigir
const NEXT_SCENE_PATH: String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

func _ready() -> void:
	# Conectar las señales de los botones (por código, para mantenerlo limpio)
	btn_login.pressed.connect(_on_login_pressed)
	btn_offline.pressed.connect(_on_offline_pressed)
	btn_exit.pressed.connect(_on_exit_pressed)

	# Conectar las señales del Autoload de Supabase.
	# IMPORTANTE: Asegúrate de que el nombre del autoload sea 'Supabase' en tu proyecto.
	Supabase.auth.signed_in.connect(_on_supabase_signed_in)
	Supabase.auth.error.connect(_on_supabase_sign_in_failed)

# --- LÓGICA DE LOS BOTONES ---

func _on_login_pressed() -> void:
	# Quitar espacios en blanco al principio y al final con strip_edges()
	var email: String = email_input.text.strip_edges()
	var password: String = password_input.text.strip_edges()

	# 1. Validar que los campos no estén vacíos
	if email.is_empty() or password.is_empty():
		if email.is_empty():
			Msg_corr.text= "El email no puede estar vacio"
			if password.is_empty():
				Msg_cont.text= "La contraseña no puede estar vacia"
		return

	# 2. Si no están vacíos, procedemos con Supabase
	print("Intentando iniciar sesión...")
	# Desactivamos el botón temporalmente para evitar múltiples clics
	btn_login.disabled = true 
	
	# Llamada al Autoload de Supabase para iniciar sesión
	Supabase.auth.sign_in(email, password)

func _on_offline_pressed() -> void:
	print("Entrando en modo sin conexión...")
	is_logged_in = false
	go_to_next_scene()

func _on_exit_pressed() -> void:
	print("Saliendo del juego...")
	get_tree().quit()


# --- RESPUESTAS DE SUPABASE ---

func _on_supabase_signed_in(_user) -> void:
	print("¡Inicio de sesión exitoso!")
	is_logged_in = true
	# Rehabilitar botón (opcional si vas a cambiar de escena de todos modos)
	btn_login.disabled = false 
	go_to_next_scene()


func _on_supabase_sign_in_failed(error) -> void:
	print("Error al iniciar sesión: ", error.message)
	is_logged_in = false
	btn_login.disabled = false 
	# Aquí podrías mostrar el error.message en un Label de tu UI
	Msg_sess.text= "Ha ocurrido un error, vuelve a iniciar sesion con un correo o contraseña validos"

# --- REDIRECCIÓN ---

func go_to_next_scene() -> void:
	# Opcional: Si tienes un Autoload llamado 'Global' para guardar el estado, hazlo aquí:
	# Global.is_user_logged_in = is_logged_in
	
	# Cambiar a la escena del juego
	var error = get_tree().change_scene_to_file(NEXT_SCENE_PATH)
	
	if error != OK:
		print("Error al cambiar de escena. Verifica la ruta: ", NEXT_SCENE_PATH)
