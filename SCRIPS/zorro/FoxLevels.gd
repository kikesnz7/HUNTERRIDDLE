# FoxLevels.gd
# Datos de todos los niveles del zorro.
# Tipos de celda: EMPTY=0, FIXED=1, MOVABLE=2, ORIGIN=3, TARGET=4, MIRROR=5(╲ haz-H→V), TOGGLE=6, ACTION_BLOCK=7, LOSS_CELL=8, MIRROR_SLASH=9(╱ haz-H→V), MIRROR_H=10(╲ haz-V→H), MIRROR_SLASH_H=11(╱ haz-V→H), MIRROR_ROT_RIGHT=12, MIRROR_ROT_LEFT=13, MIRROR_ROT_UP=14, MIRROR_ROT_DOWN=15
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
				[10, 0, 2, 0, 4],
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
		# 6×6 · PAR 5 · 2 espejos · 6 MOVABLE · 3 FIXED
		# Beam derecha → espejo [0,4] → abajo → espejo [4,4] → derecha → TARGET [4,5].
		# Mueve A[0,2], B[0,3] (orden forzado fila 0), C[2,4], E[3,4] (dos en col 4).
		# Señuelos: D[4,1], F[5,2].
		"level_4": {
			"name":      "Nivel 4",
			"size":      6,
			"beam_dir":  [0, 1],
			"moves_par": 5,
			"grid": [
				[3, 0, 2, 2, 5, 0],
				[0, 1, 0, 0, 0, 0],
				[0, 0, 1, 0, 2, 0],
				[0, 0, 0, 1, 2, 0],
				[0, 2, 0, 0, 10, 4],
				[0, 0, 2, 0, 0, 0],
			]
		},

		# ── LEVEL 5 ──────────────────────────────────────────────────────
		# 6×6 · PAR 7 · 2 espejos · 6 MOVABLE · 2 FIXED
		# Beam arriba → espejo [2,5] → izquierda → espejo [2,1] → arriba → TARGET [0,1].
		# Mueve C[4,5], E[3,5] (dos en col 5), D[2,4], B[2,3] (dos en fila 2), A[1,1].
		# Señuelo: F[0,4].
		"level_5": {
			"name":      "Nivel 5",
			"size":      6,
			"beam_dir":  [-1, 0],
			"moves_par": 7,
			"grid": [
				[0, 4, 0, 0, 2, 0],
				[0, 2, 0, 8, 1, 0],
				[0, 5, 0, 2, 2, 10],
				[0, 0, 1, 0, 0, 2],
				[0, 8, 0, 0, 0, 2],
				[0, 0, 0, 0, 0, 3],
			]
		},

		# ── LEVEL 6 ──────────────────────────────────────────────────────
		# 7×7 · PAR 7 · 2 espejos · 7 MOVABLE · 2 FIXED
		# Beam derecha → espejo [0,4] → abajo → espejo [5,4] → derecha → TARGET [5,6].
		# Mueve F[0,1], A[0,2] (dos en fila 0), B[2,4], E[4,4] (dos en col 4), C[5,5].
		# Señuelos: G[3,5], D[3,6].
		"level_6": {
			"name":      "Nivel 6",
			"size":      7,
			"beam_dir":  [0, 1],
			"moves_par": 7,
			"grid": [
				[3, 2, 2, 0, 5, 0, 8],
				[0, 1, 0, 0, 0, 8, 0],
				[0, 0, 0, 0, 2, 0, 0],
				[8, 0, 1, 0, 0, 2, 2],
				[0, 0, 0, 0, 2, 0, 0],
				[0, 0, 0, 0, 10, 2, 4],
				[0, 8, 0, 0, 0, 0, 0],
			]
		},

		# ── LEVEL 7 ──────────────────────────────────────────────────────
		# 7×7 · PAR 5 · 2 espejos + 1 MIRROR_ROT · 5 MOVABLE · 2 FIXED · 1 TOGGLE · 1 ACTION_BLOCK
		# Beam derecha → espejo [0,2] → abajo → espejo [4,2] → derecha → MIRROR_ROT[4,5] (inicial ↑)
		#             → arriba → TOGGLE[1,5] (elimina ACTION_BLOCK[5,5]).
		# Jugador tapea ↑→↓ → haz baja por [5,5]=vacío → TARGET[6,5].
		# Mueve A[0,1], E[1,2], B[2,2] (col 2), [4,4], D[3,5] (col 5).
		"level_7": {
			"name":      "Nivel 7",
			"size":      7,
			"beam_dir":  [0, 1],
			"moves_par": 5,
			"triggers":  [{"toggle": [1, 5], "action_block": [5, 5]}],
			"grid": [
				[3, 2, 5, 0, 0, 8, 0],
				[0, 0, 2, 0, 1, 6, 0],
				[0, 1, 2, 8, 0, 8, 8],
				[0, 0, 0, 0, 8, 2, 0],
				[0, 0, 10, 0, 2, 14, 0],
				[8, 0, 0, 8, 0, 7, 0],
				[0, 8, 0, 0, 8, 4, 0],
			]
		},

		# ── LEVEL 8 ──────────────────────────────────────────────────────
		# 8×8 · PAR 6 · 2 espejos + 1 MIRROR_ROT · 5 MOVABLE · 3 FIXED · 1 TOGGLE · 1 ACTION_BLOCK
		# Beam derecha → espejo [0,3] → abajo → TOGGLE[3,3] (elimina ACTION_BLOCK[5,5])
		#             → espejo [5,3] → derecha → MIRROR_ROT[5,6] (inicial ↑ → decoy G[2,6])
		# Jugador tapea ↑→↓ → haz baja → D[6,6] → TARGET[7,6].
		# Mueve F[0,1], A[0,2] (dos en fila 0), B[1,3], C[2,3] (dos en col 3), D[6,6].
		# Señuelos: E[1,7], G[2,6].
		"level_8": {
			"name":      "Nivel 8",
			"size":      8,
			"beam_dir":  [0, 1],
			"moves_par": 6,
			"triggers":  [{"toggle": [3, 3], "action_block": [5, 5]}],
			"grid": [
				[3, 2, 2, 5, 0, 0, 0, 0],
				[0, 1, 0, 2, 8, 8, 0, 2],
				[0, 8, 0, 2, 8, 8, 2, 0],
				[0, 0, 1, 6, 8, 8, 0, 0],
				[8, 0, 8, 0, 0, 0, 0, 0],
				[0, 0, 8, 10, 0, 7, 14, 0],
				[0, 8, 0, 0, 1, 0, 2, 0],
				[0, 8, 0, 0, 8, 8, 4, 0],
			]
		},

		# ── LEVEL 9 ──────────────────────────────────────────────────────
		# 8×8 · PAR 6 · 1 MIRROR_ROT · 5 MOVABLE · 1 FIXED · 2 TOGGLE · 2 ACTION_BLOCK
		# Beam izquierda → TOGGLE[7,4] (elimina ACTION_BLOCK[3,1])
		#              → MIRROR_ROT[7,1] (inicial ← sale por el borde)
		# Jugador tapea ←→↑ → haz sube col 1 → TOGGLE[2,1] (elimina ACTION_BLOCK[1,1]) → TARGET[0,1].
		# Mueve B[7,6], E[7,5] (fila 7), D[6,1], A[5,1], F[4,1] (col 1).
		"level_9": {
			"name":      "Nivel 9",
			"size":      8,
			"beam_dir":  [0, -1],
			"moves_par": 6,
			"triggers":  [
				{"toggle": [7, 4], "action_block": [3, 1]},
				{"toggle": [2, 1], "action_block": [1, 1]},
			],
			"grid": [
				[0, 4, 0, 0, 0, 0, 8, 0],
				[8, 7, 8, 0, 8, 0, 0, 8],
				[8, 6, 8, 0, 8, 1, 0, 0],
				[0, 7, 8, 8, 0, 8, 0, 0],
				[0, 2, 0, 0, 0, 8, 0, 0],
				[0, 2, 8, 0, 8, 8, 0, 8],
				[8, 2, 8, 0, 0, 8, 8, 0],
				[0, 13, 0, 0, 6, 2, 2, 3],
			]
		},

		# ── LEVEL 10 ─────────────────────────────────────────────────────
		# 9×9 · PAR 8 · 3 espejos + 1 MIRROR_ROT · 8 MOVABLE · 3 FIXED · 2 TOGGLE · 2 ACTION_BLOCK
		# Beam derecha → espejo [0,4] → abajo → TOGGLE[3,4] (elimina ACTION_BLOCK[5,6])
		#             → I[4,4] → espejo [5,4] → derecha → MIRROR_ROT[5,7] (inicial ↑ → señuelo J[3,7]).
		# Jugador tapea ↑→↓ → haz baja → TOGGLE[6,7] (elimina ACTION_BLOCK[7,7])
		#             → espejo [8,7] → derecha → TARGET[8,8].
		# Mueve H[0,1], A[0,2] (dos en fila 0), F[1,4], B[2,4], I[4,4] (tres en col 4), G[5,5].
		# Señuelos: E[1,7], J[3,7].
		"level_10": {
			"name":      "Nivel 10",
			"size":      9,
			"beam_dir":  [0, 1],
			"moves_par": 8,
			"triggers":  [
				{"toggle": [3, 4], "action_block": [5, 6]},
				{"toggle": [6, 7], "action_block": [7, 7]},
			],
			"grid": [
				[3, 2, 2, 0, 5, 8, 0, 8, 8],
				[8, 1, 0, 8, 2, 0, 8, 2, 8],
				[8, 0, 8, 0, 2, 8, 8, 0, 8],
				[8, 8, 0, 1, 6, 0, 8, 2, 0],
				[8, 0, 8, 0, 2, 0, 0, 0, 8],
				[0, 8, 8, 0, 10, 2, 7, 14, 8],
				[8, 8, 8, 8, 8, 1, 8, 6, 8],
				[8, 0, 8, 0, 8, 8, 8, 7, 0],
				[0, 0, 0, 8, 8, 8, 0, 10, 4],
			]
		},
	}
