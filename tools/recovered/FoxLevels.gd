# FoxLevels.gd
# Datos de todos los niveles del zorro.
# Tipos de celda: EMPTY=0, FIXED=1, MOVABLE=2, ORIGIN=3, TARGET=4, MIRROR=5, TOGGLE=6
# beam_dir: [fila, col] — RIGHT=[0,1], LEFT=[0,-1], DOWN=[1,0], UP=[-1,0]
# El espejo (╲) redirige: RIGHT↔DOWN  |  LEFT↔UP
# TOGGLE empieza bloqueante (toggled=true). El jugador pulsa para desbloquear (no cuenta como movimiento).
extends Node

static func get_level(level_id: String) -> Dictionary:
	var levels := _all_levels()
	return levels.get(level_id, {})

static func _all_levels() -> Dictionary:
	return {

		# ── TUTORIAL ─────────────────────────────────────────────────────
		# 4×4 · PAR 2 · 0 espejos · 1 MOVABLE · 1 FIXED
		# Beam derecha recto. Mueve [1,1] a cualquier hueco.
		"tutorial": {
			"name":      "Tutorial",
			"size":      4,
			"beam_dir":  [0, 1],
			"moves_par": 2,
			"grid": [
				[0, 0, 0, 0],
				[3, 2, 0, 4],
				[0, 0, 0, 0],
				[0, 1, 0, 0],
			]
		},

		# ── LEVEL 1 ──────────────────────────────────────────────────────
		# 4×4 · PAR 3 · 1 espejo · 2 MOVABLE · 1 FIXED
		# Beam derecha → espejo [0,2] → abajo → TARGET [3,2].
		# Mueve [1,2]. Señuelo: [3,3].
		"level_1": {
			"name":      "Nivel 1",
			"size":      4,
			"beam_dir":  [0, 1],
			"moves_par": 3,
			"grid": [
				[3, 0, 5, 0],
				[0, 1, 2, 0],
				[0, 0, 0, 0],
				[0, 0, 4, 2],
			]
		},

		# ── LEVEL 2 ──────────────────────────────────────────────────────
		# 5×5 · PAR 4 · 1 espejo · 3 MOVABLE · 2 FIXED
		# Beam abajo → espejo [4,0] → derecha → TARGET [4,4].
		# Mueve [3,0] y [4,2]. Señuelo: [1,4].
		"level_2": {
			"name":      "Nivel 2",
			"size":      5,
			"beam_dir":  [1, 0],
			"moves_par": 4,
			"grid": [
				[0, 0, 0, 0, 0],
				[0, 1, 0, 0, 2],
				[3, 0, 0, 0, 0],
				[2, 0, 0, 1, 0],
				[5, 0, 2, 0, 4],
			]
		},

		# ── LEVEL 3 ──────────────────────────────────────────────────────
		# 5×5 · PAR 4 · 1 espejo · 3 MOVABLE · 2 FIXED
		# Beam izquierda → espejo [4,1] → arriba → TARGET [0,1].
		# Mueve [4,3] y [2,1]. Señuelo: [1,3].
		"level_3": {
			"name":      "Nivel 3",
			"size":      5,
			"beam_dir":  [0, -1],
			"moves_par": 4,
			"grid": [
				[0, 4, 0, 0, 0],
				[0, 0, 0, 2, 1],
				[0, 2, 0, 0, 0],
				[1, 0, 0, 0, 0],
				[0, 5, 0, 2, 3],
			]
		},

		# ── LEVEL 4 ──────────────────────────────────────────────────────
		# 6×6 · PAR 5 · 2 espejos · 3 MOVABLE · 2 FIXED
		# Beam derecha → espejo [0,4] → abajo → espejo [4,4] → derecha → TARGET [4,5].
		# Mueve [0,2] y [2,4]. Señuelo: [4,1].
		"level_4": {
			"name":      "Nivel 4",
			"size":      6,
			"beam_dir":  [0, 1],
			"moves_par": 5,
			"grid": [
				[3, 0, 2, 0, 5, 0],
				[0, 1, 0, 0, 0, 0],
				[0, 0, 0, 0, 2, 0],
				[0, 0, 0, 1, 0, 0],
				[0, 2, 0, 0, 5, 4],
				[0, 0, 0, 0, 0, 0],
			]
		},

		# ── LEVEL 5 ──────────────────────────────────────────────────────
		# 6×6 · PAR 6 · 2 espejos · 4 MOVABLE · 2 FIXED
		# Beam arriba → espejo [2,5] → izquierda → espejo [2,1] → arriba → TARGET [0,1].
		# Mueve [4,5], [2,3] y [1,1]. Señuelo: [0,4].
		"level_5": {
			"name":      "Nivel 5",
			"size":      6,
			"beam_dir":  [-1, 0],
			"moves_par": 6,
			"grid": [
				[0, 4, 0, 0, 2, 0],
				[0, 2, 0, 0, 1, 0],
				[0, 5, 0, 2, 0, 5],
				[0, 0, 1, 0, 0, 0],
				[0, 0, 0, 0, 0, 2],
				[0, 0, 0, 0, 0, 3],
			]
		},

		# ── LEVEL 6 ──────────────────────────────────────────────────────
		# 7×7 · PAR 6 · 2 espejos · 4 MOVABLE · 2 FIXED
		# Beam derecha → espejo [0,4] → abajo → espejo [5,4] → derecha → TARGET [5,6].
		# Mueve [0,2], [2,4] y [5,5]. Señuelo: [3,6].
		"level_6": {
			"name":      "Nivel 6",
			"size":      7,
			"beam_dir":  [0, 1],
			"moves_par": 6,
			"grid": [
				[3, 0, 2, 0, 5, 0, 0],
				[0, 1, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 2, 0, 0],
				[0, 0, 1, 0, 0, 0, 2],
				[0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 5, 2, 4],
				[0, 0, 0, 0, 0, 0, 0],
			]
		},

		# ── LEVEL 7 ──────────────────────────────────────────────────────
		# 7×7 · PAR 5 · 3 espejos · 4 MOVABLE · 2 FIXED · 1 TOGGLE
		# Beam derecha → espejo [0,2] → abajo → TOGGLE [3,2] → espejo [4,2]
		#             → derecha → espejo [4,5] → abajo → TARGET [6,5].
		# Mueve [0,1], [2,2], [4,4]. Tap TOGGLE [3,2]. Señuelo: [5,6].
		"level_7": {
			"name":      "Nivel 7",
			"size":      7,
			"beam_dir":  [0, 1],
			"moves_par": 5,
			"grid": [
				[3, 2, 5, 0, 0, 0, 0],
				[0, 0, 0, 0, 1, 0, 0],
				[0, 1, 2, 0, 0, 0, 0],
				[0, 0, 6, 0, 0, 0, 0],
				[0, 0, 5, 0, 2, 5, 0],
				[0, 0, 0, 0, 0, 0, 2],
				[0, 0, 0, 0, 0, 4, 0],
			]
		},

		# ── LEVEL 8 ──────────────────────────────────────────────────────
		# 8×8 · PAR 5 · 3 espejos · 5 MOVABLE · 3 FIXED · 1 TOGGLE
		# Beam derecha → espejo [0,3] → abajo → TOGGLE [3,3] → espejo [5,3]
		#             → derecha → espejo [5,6] → abajo → TARGET [7,6].
		# Mueve [0,2], [2,3], [5,5], [6,6]. Tap TOGGLE [3,3]. Señuelo: [1,7].
		"level_8": {
			"name":      "Nivel 8",
			"size":      8,
			"beam_dir":  [0, 1],
			"moves_par": 5,
			"grid": [
				[3, 0, 2, 5, 0, 0, 0, 0],
				[0, 1, 0, 0, 0, 0, 0, 2],
				[0, 0, 0, 2, 0, 0, 0, 0],
				[0, 0, 1, 6, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 5, 0, 2, 5, 0],
				[0, 0, 0, 0, 1, 0, 2, 0],
				[0, 0, 0, 0, 0, 0, 4, 0],
			]
		},

		# ── LEVEL 9 ──────────────────────────────────────────────────────
		# 8×8 · PAR 4 · 3 espejos · 4 MOVABLE · 2 FIXED · 2 TOGGLE
		# Beam izquierda → espejo [7,4] → arriba → TOGGLE [4,4] → espejo [3,4]
		#              → izquierda → espejo [3,1] → arriba → TOGGLE [2,1] → TARGET [0,1].
		# Mueve [7,6], [5,4], [3,2]. Tap TOGGLE [4,4] y [2,1]. Señuelo: [6,1].
		"level_9": {
			"name":      "Nivel 9",
			"size":      8,
			"beam_dir":  [0, -1],
			"moves_par": 4,
			"grid": [
				[0, 4, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0],
				[0, 6, 0, 0, 0, 1, 0, 0],
				[0, 5, 2, 0, 5, 0, 0, 0],
				[0, 0, 0, 0, 6, 0, 0, 0],
				[0, 0, 1, 0, 2, 0, 0, 0],
				[0, 2, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 5, 0, 2, 3],
			]
		},

		# ── LEVEL 10 ─────────────────────────────────────────────────────
		# 9×9 · PAR 4 · 4 espejos · 5 MOVABLE · 3 FIXED · 2 TOGGLE
		# Beam derecha → espejo [0,4] → abajo → TOGGLE [3,4] → espejo [5,4]
		#             → derecha → espejo [5,7] → abajo → TOGGLE [6,7]
		#             → espejo [8,7] → derecha → TARGET [8,8].
		# Mueve [0,2], [2,4], [5,6], [7,7]. Tap TOGGLE [3,4] y [6,7]. Señuelo: [1,7].
		"level_10": {
			"name":      "Nivel 10",
			"size":      9,
			"beam_dir":  [0, 1],
			"moves_par": 4,
			"grid": [
				[3, 0, 2, 0, 5, 0, 0, 0, 0],
				[0, 1, 0, 0, 0, 0, 0, 2, 0],
				[0, 0, 0, 0, 2, 0, 0, 0, 0],
				[0, 0, 0, 1, 6, 0, 0, 0, 0],
				[0, 0, 0, 0, 0, 0, 0, 0, 0],
				[0, 0, 0, 0, 5, 0, 2, 5, 0],
				[0, 0, 0, 0, 0, 1, 0, 6, 0],
				[0, 0, 0, 0, 0, 0, 0, 2, 0],
				[0, 0, 0, 0, 0, 0, 0, 5, 4],
			]
		},
	}
