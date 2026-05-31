# ZorroScreen.gd
# Ubicación: res://Escenas/UI/ZORRO/ZorroScreen.gd
extends Control

signal back_pressed
signal level_selected(level_id: int)
signal ranking_pressed

const ANIMAL_ID    = "fox"
const PUZZLE_SCENE = "res://Escenas/UI/ZORRO/PuzzleZorro.tscn"
const FOX_MID      = Color("#D4622A")
const FOX_LIGHT    = Color("#F2C4A8")
const NEXT_SCENE_PATH_MENU  = "res://Escenas/StartMenu.tscn"
const GLOBAL_STARS_PATH     : String = "res://Escenas/UI/GlobalStars.tscn"
const MAX_SCORE_PER_LEVEL   : int    = 150   # 100 tiempo + 50 bonus 3 estrellas
const LEVELS_COUNT          : int    = 10    # sin contar tutorial
const TEN_EN_CUENTA_PATH    : String = "res://Escenas/UI/TenEnCuenta.tscn"
# Pares de movimientos por nivel
const LEVEL_PARS = {
	"tutorial": 2,
	"level_1":  3, "level_2":  4, "level_3":  4,
	"level_4":  5, "level_5":  7, "level_6":  7,
	"level_7":  5, "level_8":  6, "level_9":  6,
	"level_10": 8,
}

const LEVEL_NAMES = {
	"tutorial": "Primer rayo",
	"level_1":  "El reflejo",  "level_2":  "Desvío",
	"level_3":  "Zigzag",      "level_4":  "Doble rebote",
	"level_5":  "Laberinto",   "level_6":  "Encrucijada",
	"level_7":  "Eslabones",   "level_8":  "La cadena",
	"level_9":  "Sin margen",  "level_10": "Maestría",
}

@onready var top_bar        = find_child("TopBar",                true, false)
@onready var back_btn        = find_child("BackBtn",                true, false)
@onready var levels_scroll  = find_child("ScrollContainer", true, false)
@onready var bottom_bar     = find_child("BottomBar",             true, false)
@onready var progress_band  = find_child("ProgressBand",          true, false)
@onready var nav_inicio     = find_child("NavItem_inicio",        true, false)
@onready var nav_niveles    = find_child("NavItem_Niveles",       true, false)
@onready var nav_ranking    = find_child("NavItem_Ranking",       true, false)

func _ready():
	AudioManager.play_menu_music()
	_setup_nav()
	ProgressManager.level_unlocked.connect(_on_level_unlocked)
	back_btn.pressed.connect(_on_back_pressed)
	if ANIMAL_ID in ProgressManager._loaded_animals:
		# Los datos en memoria ya están actualizados (venimos de un puzzle o recarga)
		_on_progress_loaded()
	else:
		# Primera carga de la sesión: trae el progreso desde Supabase o archivo
		ProgressManager.progress_loaded.connect(_on_progress_loaded, CONNECT_ONE_SHOT)
		if ProgressManager.is_guest:
			ProgressManager.load_local(ANIMAL_ID)
		else:
			ProgressManager.load_supabase(ANIMAL_ID)

func _on_progress_loaded():
	await get_tree().process_frame
	_setup_scroll_signal()
	_setup_progress()
	_setup_stats()
	_setup_levels()

# ─────────────────────────────────────────────
# SCROLL
# ─────────────────────────────────────────────

func _setup_scroll_signal():
	if not levels_scroll:
		return
	levels_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

func _on_scroll_changed(value: float):
	var scroll_bar = levels_scroll.get_v_scroll_bar()
	var max_val    = scroll_bar.max_value - scroll_bar.page
	var ratio      = value / max_val if max_val > 0 else 0.0
	var dots       = find_child("DotsContainer", true, false)
	if not dots:
		return
	var active = int(ratio * 3.0)
	var i = 0
	for dot in dots.get_children():
		dot.modulate = FOX_MID if i == active else FOX_LIGHT
		i += 1

# ─────────────────────────────────────────────
# PROGRESO
# ─────────────────────────────────────────────

func _setup_progress():
	if not progress_band:
		return
	var total_score := ProgressManager.get_total_score(ANIMAL_ID)
	var max_score   := LEVELS_COUNT * MAX_SCORE_PER_LEVEL
	progress_band.max_points = max_score
	progress_band.set_progress(total_score, "dificultad fácil")

# ─────────────────────────────────────────────
# ESTADÍSTICAS
# ─────────────────────────────────────────────

func _setup_stats():
	var data      = ProgressManager.get_animal_progress(ANIMAL_ID)
	var done      = 0
	var best_time = 0.0

	for level in data.values():
		if level["state"] == "done":
			done += 1
			var t = level["best_time"]
			if t > 0.0 and (best_time == 0.0 or t < best_time):
				best_time = t

	var pill_c = find_child("StatPillCompletados", true, false)
	var pill_t = find_child("StatPillTiempo",      true, false)
	var pill_p = find_child("StatPillPuntos",      true, false)

	var total_score := ProgressManager.get_total_score(ANIMAL_ID)
	if pill_c: pill_c.set_stat(str(done), "completados")
	if pill_t: pill_t.set_stat(_fmt_time(best_time), "mejor tiempo")
	if pill_p: pill_p.set_stat(str(total_score), "puntos")

func _fmt_time(s: float) -> String:
	if s <= 0.0: return "—"
	return "%02d:%02d" % [int(s) / 60, int(s) % 60]

# ─────────────────────────────────────────────
# TARJETAS DE NIVEL
# ─────────────────────────────────────────────

func _setup_levels():
	var vbox = find_child("LevelsGrid", true, false)
	if not vbox:
		return
	for card in vbox.get_children():
		if card.get("level_number") == null:
			continue

		var level_id_str := _number_to_level_id(card.level_number)
		var state_str := ProgressManager.get_level_state(ANIMAL_ID, level_id_str)
		card.state = _str_to_state(state_str)
		card.stars = ProgressManager.get_level_stars(ANIMAL_ID, level_id_str)
		if card.get("level_name") != null:
			card.level_name = LEVEL_NAMES.get(level_id_str, "")

		if state_str != "locked":
			if not card.card_pressed.is_connected(_on_card_level_pressed):
				card.card_pressed.connect(_on_card_level_pressed)
func _on_back_pressed():
	ConfirmExitDialog.ask(func():
		go_to_next_scene()
	)
func go_to_next_scene()-> void:
	# Opcional: Si tienes un Autoload llamado 'Global' para guardar el estado, hazlo aquí:
	# Global.is_user_logged_in = is_logged_in
	
	# Cambiar a la escena del juego
	var error = get_tree().change_scene_to_file(NEXT_SCENE_PATH_MENU)
	
	if error != OK:
		print("Error al cambiar de escena. Verifica la ruta: ", NEXT_SCENE_PATH_MENU)
func _str_to_state(state_str: String) -> int:
	match state_str:
		"done":     return 0   # LevelCard.State.DONE
		"unlocked": return 1   # LevelCard.State.UNLOCKED
		_:          return 2   # LevelCard.State.LOCKED

func _on_card_level_pressed(level_num: int):
	var level_id := _number_to_level_id(level_num)
	GameState.current_animal = ANIMAL_ID
	GameState.current_level  = level_id
	GameState.current_par    = LEVEL_PARS.get(level_id, 3)
	get_tree().change_scene_to_file(PUZZLE_SCENE)
	emit_signal("level_selected", level_num)

func _number_to_level_id(number: int) -> String:
	if number == 0:
		return "tutorial"
	return "level_%d" % number

# ─────────────────────────────────────────────
# DESBLOQUEO EN TIEMPO REAL
# ─────────────────────────────────────────────

func _on_level_unlocked(animal_id: String, level_id: String):
	if animal_id != ANIMAL_ID:
		return
	var vbox = find_child("LevelsGrid", true, false)
	if not vbox:
		return
	for card in vbox.get_children():
		if card.get("level_number") == null:
			continue
		if _number_to_level_id(card.level_number) != level_id:
			continue
		card.state = 1   # UNLOCKED
		if not card.card_pressed.is_connected(_on_card_level_pressed):
			card.card_pressed.connect(_on_card_level_pressed)
		# Animación fade-in
		card.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(card, "modulate:a", 1.0, 0.4)\
			.set_ease(Tween.EASE_OUT)
		# Scroll hasta la tarjeta desbloqueada
		await get_tree().process_frame
		if levels_scroll:
			levels_scroll.ensure_control_visible(card)
		break

# ─────────────────────────────────────────────
# NAVEGACIÓN
# ─────────────────────────────────────────────

func _setup_nav():
	if nav_inicio:
		nav_inicio.set_active(true)
		nav_inicio.gui_input.connect(_on_nav_inicio)
	if nav_niveles:
		nav_niveles.set_active(true)
	if nav_ranking:
		nav_ranking.set_active(true)
		nav_ranking.gui_input.connect(_on_nav_ranking)
	var tut_btn := find_child("botonInicioNivel", true, false)
	if tut_btn:
		tut_btn.pressed.connect(_on_tutorial_btn_pressed)
	_setup_tec_button()

func _on_nav_inicio(event: InputEvent):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		get_tree().change_scene_to_file(NEXT_SCENE_PATH_MENU)

func _on_tutorial_btn_pressed() -> void:
	GameState.current_animal = ANIMAL_ID
	GameState.current_level  = "tutorial"
	GameState.current_par    = LEVEL_PARS.get("tutorial", 2)
	get_tree().change_scene_to_file(PUZZLE_SCENE)

func _setup_tec_button() -> void:
	var levels_section := find_child("LevelsSection", true, false)
	if not levels_section:
		return
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	var btn_tec := Button.new()
	btn_tec.text = "Ten en cuenta"
	btn_tec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_tec.pressed.connect(_on_ten_en_cuenta_pressed)
	margin.add_child(btn_tec)
	levels_section.add_child(margin)
	levels_section.move_child(margin, 1)

func _on_ten_en_cuenta_pressed() -> void:
	get_tree().change_scene_to_file(TEN_EN_CUENTA_PATH)

func _on_nav_ranking(event: InputEvent):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		GameState.ranking_return_scene  = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"
		GameState.ranking_filter_animal = ANIMAL_ID
		get_tree().change_scene_to_file(GLOBAL_STARS_PATH)
		emit_signal("ranking_pressed")
