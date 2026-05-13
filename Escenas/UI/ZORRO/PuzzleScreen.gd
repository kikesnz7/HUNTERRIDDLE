extends Control

# ── Constantes de puntuación ───────────────────────────────────────────────
const SCORE_BASE      := 100
const SCORE_PENALTY   := -10
const SCORE_PAR_BONUS := 50
const NEXT_SCENE_PATH_MENU: String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

# ── Referencias a nodos ───────────────────────────────────────────────────
@onready var level_title   : Label         = find_child("LevelTitle",   true, false)
@onready var move_counter  : Label         = find_child("MoveCounter",  true, false)
@onready var timer_label   : Label         = find_child("TimerLabel",   true, false)
@onready var par_label     : Label         = find_child("ParLabel",     true, false)
@onready var simulate_btn  : Button        = find_child("SimulateBtn",  true, false)
@onready var reset_btn     : Button        = find_child("ResetBtn",     true, false)
@onready var board         : Node          = find_child("Board",        true, false)
@onready var overlay       : CanvasLayer   = find_child("CompletionOverlay", true, false)
@onready var completion_msg: Label         = find_child("CompletionMsg", true, false)
@onready var score_label   : Label         = find_child("ScoreLabel",   true, false)
@onready var next_btn      : Button        = find_child("NextBtn",      true, false)
@onready var menu_btn      : Button        = find_child("MenuBtn",      true, false)

# ── Estado ────────────────────────────────────────────────────────────────
var _level_data   : Dictionary = {}
var _moves        : int = 0
var _elapsed      : float = 0.0
var _timer_active : bool = false

signal level_completed(score: int)
signal back_pressed
signal menu_pressed
# ── Ciclo de vida ─────────────────────────────────────────────────────────
func _ready() -> void:
	await get_tree().process_frame

	var back_btn := find_child("BackBtn", true, false)
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	else:
		push_warning("BackBtn no encontrado en PuzzleScreen")

	var sim := find_child("SimulateBtn", true, false)
	if sim:
		sim.pressed.connect(_on_simulate_pressed)

	var res := find_child("ResetBtn", true, false)
	if res:
		res.pressed.connect(_on_reset_pressed)

	var nxt := find_child("NextBtn", true, false)
	if nxt:
		nxt.pressed.connect(_on_next_pressed)

	var menu := find_child("MenuBtn", true, false)
	if menu:
		menu.pressed.connect(_on_menu_pressed)

	if board:
		board.block_moved.connect(_on_block_moved)
		board.beam_reached_target.connect(_on_beam_reached_target)
	else:
		push_warning("Board no encontrado en PuzzleScreen")
	# Nivel de prueba temporal
	#estilo JSON para mayor entendimiento jeje, asi mucho mejor
	var test_level := {
	"name": "Nivel Ejemplo",
	"size": 5,
	"grid": [
		[0, 1, 0, 0, 0],
		[3, 0, 2, 0, 5],
		[0, 0, 0, 2, 0],
		[0, 1, 0, 0, 0],
		[5, 0, 0, 0, 4]
	],
	"moves_par": 3,
	"beam_dir": Vector2i(0, 1)   # ← dirección inicial: derecha
}
	load_level(test_level)
func _process(delta: float) -> void:
	if _timer_active:
		_elapsed += delta
		_update_timer_label()

# ── API pública ───────────────────────────────────────────────────────────
func load_level(data: Dictionary) -> void:
	_level_data = data
	_moves      = 0
	_elapsed    = 0.0
	_timer_active = true
	overlay.visible = false
	print("Cargandonivel... ")
	level_title.text  = data.get("name", "Nivel")
	par_label.text    = "Par: %d" % data.get("moves_par", 0)
	_refresh_move_counter()

	board.setup(data)

# ── Callbacks de UI ───────────────────────────────────────────────────────
func _on_simulate_pressed() -> void:
	board.simulate_beam()

func _on_reset_pressed() -> void:
	load_level(_level_data)   # recarga el nivel desde cero

func _on_back_pressed() -> void:
	emit_signal("back_pressed")

func _on_menu_pressed() -> void:
	emit_signal("menu_pressed")
	go_to_next_scene()

func _on_next_pressed() -> void:
	pass  # el padre decide qué nivel cargar a continuación

# ── Callbacks del Board ───────────────────────────────────────────────────
func _on_block_moved() -> void:
	_moves += 1
	_refresh_move_counter()

#Esto es una vez que el haz de luz llega a su destino
func _on_beam_reached_target() -> void:
	_timer_active = false
	var par: int
	par = _level_data.get("moves_par", 0)
	var extra    : int = max(0, _moves - par)
	var score    : int = SCORE_BASE + extra * SCORE_PENALTY
	if extra == 0:
		score += SCORE_PAR_BONUS

	score_label.text = "+%d pts" % score
	_show_completion_overlay()
	emit_signal("level_completed", score)

# ── Helpers ───────────────────────────────────────────────────────────────
func _refresh_move_counter() -> void:
	var par: int
	par = _level_data.get("moves_par", 0)
	move_counter.text = "Movs: %d / par %d" % [_moves, par]
	
func go_to_next_scene() -> void:
	# Opcional: Si tienes un Autoload llamado 'Global' para guardar el estado, hazlo aquí:
	# Global.is_user_logged_in = is_logged_in
	
	# Cambiar a la escena del juego
	var error = get_tree().change_scene_to_file(NEXT_SCENE_PATH_MENU)
	
	if error != OK:
		print("Error al cambiar de escena. Verifica la ruta: ", NEXT_SCENE_PATH_MENU)

func _update_timer_label() -> void:
	var m := int(_elapsed) / 60
	var s := int(_elapsed) % 60
	timer_label.text = "%d:%02d" % [m, s]

func _show_completion_overlay() -> void:
	overlay.visible = true
	var panel := find_child("CompletionPanel", true, false)
	panel.modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)
