# PuzzleManager.gd
# Nodo dentro de PuzzleScreen
extends Node

signal level_completed(animal_id: String, level_id: String, score: int, stars: int, time: float)

var animal_id   : String = "fox"
var level_id    : String = "level_1"
var moves_par   : int    = 3
var moves_done  : int    = 0
var elapsed     : float  = 0.0
var running     : bool   = false
var resets_used : int    = 0

# ─────────────────────────────────────────────
# INICIAR NIVEL
# ─────────────────────────────────────────────

func start_level(a_id: String, l_id: String, par: int):
	animal_id  = a_id
	level_id   = l_id
	moves_par  = par
	moves_done = 0
	elapsed    = 0.0
	running    = true

func _process(delta: float):
	if running:
		elapsed += delta

# ─────────────────────────────────────────────
# REGISTRAR MOVIMIENTO — llamar cada vez que el jugador mueve un bloque
# ─────────────────────────────────────────────

func register_move():
	if not running:
		return
	moves_done += 1

# ─────────────────────────────────────────────
# COMPLETAR — llamar desde Board.gd cuando el haz llega al TARGET
# ─────────────────────────────────────────────

func complete():
	if not running:
		return
	running = false

	var score = _calculate_score()
	var stars = _calculate_stars()

	# Guarda en ProgressManager — él decide local o Supabase
	await ProgressManager.complete_level(animal_id, level_id, stars, elapsed)

	emit_signal("level_completed", animal_id, level_id, score, stars, elapsed)

func _calculate_score() -> int:
	var extra   = max(0, moves_done - moves_par)
	var bonus   = 50 if extra == 0 else 0
	return max(0, 100 - extra * 10 + bonus)

func _calculate_stars() -> int:
	var extra = moves_done - moves_par
	var base  = 3 if extra <= 0 else (2 if extra <= 2 else 1)
	# El primer reset es gratis; cada reset adicional baja 1 estrella
	return max(1, base - max(0, resets_used - 1))
