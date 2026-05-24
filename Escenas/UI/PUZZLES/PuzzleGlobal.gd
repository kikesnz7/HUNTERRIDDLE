# PuzzleScreen.gd
# Ubicación: res://Escenas/Puzzles/PuzzleScreen.gd
# Asignar al nodo raíz de PuzzleScreen.tscn
extends Control
 
const FOX_SCENE     = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"
# aun no estan
#const OWL_SCENE     = "res://Escenas/UI/BUHO/BuhoScreen.tscn"
#const DOLPHIN_SCENE = "res://Escenas/UI/DELFIN/DelfinScreen.tscn"
#const RAVEN_SCENE   = "res://Escenas/UI/CUERVO/CuervoScreen.tscn"
 
@onready var puzzle_manager    = $PuzzleManager
@onready var board             = $BoardContainer/Board
@onready var completion_overlay = $CompletionOverlay
 
func _ready():
	# Conecta señales del PuzzleManager
	puzzle_manager.level_completed.connect(_on_level_completed)
 
	# Arranca el nivel con los datos que dejó FoxScreen en GameState
	puzzle_manager.start_level(
		GameState.current_animal,
		GameState.current_level,
		GameState.current_par
	)
 
func _on_level_completed(animal_id: String, level_id: String,
						  score: int, stars: int, time: float):
	# Muestra el overlay de fin de nivel
	completion_overlay.show_result(score, stars, time, animal_id, level_id)
 
# Llamado por CompletionOverlay cuando el jugador pulsa "Siguiente"
func go_to_next_level():
	var order  = ProgressManager.LEVEL_ORDER.get(GameState.current_animal, [])
	var idx    = order.find(GameState.current_level)
	if idx == -1 or idx >= order.size() - 1:
		# Era el último nivel — vuelve al menú del animal
		_go_to_animal_screen()
		return
	GameState.current_level = order[idx + 1]
	GameState.current_par   = _get_par(GameState.current_animal, GameState.current_level)
	get_tree().reload_current_scene()
 
# Llamado por CompletionOverlay cuando el jugador pulsa "Menú"
func go_to_menu():
	_go_to_animal_screen()
 
func _go_to_animal_screen():
	match GameState.current_animal:
		"fox":     get_tree().change_scene_to_file(FOX_SCENE)
		#"owl":     get_tree().change_scene_to_file(OWL_SCENE)
		#"dolphin": get_tree().change_scene_to_file(DOLPHIN_SCENE)
		#"raven":   get_tree().change_scene_to_file(RAVEN_SCENE)
 
func _get_par(animal: String, level: String) -> int:
	# Define aquí el par de movimientos de cada nivel
	# Más adelante esto vendrá de un archivo de datos de nivel
	var pars = {
		"fox": {
			"tutorial": 2,
			"level_1":  3, "level_2":  4, "level_3":  4,
			"level_4":  5, "level_5":  7, "level_6":  7,
			"level_7":  5, "level_8":  6, "level_9":  6,
			"level_10": 8,
		},
		#"owl": {
			#"tutorial": 0, "level_1": 0,
			#"level_2":  0, "level_3": 0, "level_4": 0
		#},
		#"dolphin": {
			#"tutorial": 0, "level_1": 0,
			#"level_2":  0, "level_3": 0, "level_4": 0
		#},
		#"raven": {
			#"tutorial": 0, "level_1": 0,
			#"level_2":  0, "level_3": 0, "level_4": 0
		#},
	}
	return pars.get(animal, {}).get(level, 3)
