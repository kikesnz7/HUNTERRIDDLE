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
@onready var puzzle_manager                = find_child("PuzzleManager", true, false)
# ── Estado ────────────────────────────────────────────────────────────────
var _level_data   : Dictionary = {}
var _moves        : int = 0
var _elapsed      : float = 0.0
var _timer_active : bool = false
var _resets_used        : int = 0
var _loss_overlay       : CanvasLayer = null
var _completion_overlay : CanvasLayer = null
var _tutorial_overlay   : CanvasLayer = null
var _tutorial_done_btn  : Button      = null

signal level_completed(score: int)
signal back_pressed
signal menu_pressed
# ── Ciclo de vida ─────────────────────────────────────────────────────────
func _ready() -> void:
	AudioManager.play_puzzle_music()
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

	if board:
		board.block_moved.connect(_on_block_moved)
		board.beam_reached_target.connect(_on_beam_reached_target)
		board.block_on_loss_cell.connect(_on_block_on_loss_cell)
		board.mirror_flipped.connect(_on_mirror_flipped)
	else:
		push_warning("Board no encontrado en PuzzleScreen")
	var level_data := FoxLevels.get_level(GameState.current_level)
	if level_data.is_empty():
		push_error("FoxLevels: nivel no encontrado: " + GameState.current_level)
		return
	var saved = ProgressManager.load_mid_level(GameState.current_animal, GameState.current_level)
	if not saved.is_empty():
		var resume_data = level_data.duplicate()
		resume_data["grid"]    = saved["grid"]
		resume_data["toggles"] = saved.get("toggles", [])
		load_level(resume_data)
		_level_data = level_data
		_moves   = saved.get("moves", 0)
		_elapsed = saved.get("elapsed", 0.0)
		_refresh_move_counter()
	else:
		load_level(level_data)

	if puzzle_manager:
		puzzle_manager.start_level(
			GameState.current_animal,
			GameState.current_level,
			GameState.current_par
		)

	_check_all_tutorials()

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
	if _completion_overlay:
		_completion_overlay.queue_free()
		_completion_overlay = null
	level_title.text  = data.get("name", "Nivel")
	par_label.text    = "Par: %d" % data.get("moves_par", 0)
	_refresh_move_counter()
	_refresh_reset_label()
	board.setup(data)

# ── Callbacks de UI ───────────────────────────────────────────────────────
func _on_simulate_pressed() -> void:
	board.simulate_beam()

func _on_reset_pressed() -> void:
	_resets_used += 1
	if puzzle_manager:
		puzzle_manager.resets_used = _resets_used
	AudioManager.play_sfx("reset")
	_do_reset()

func _do_reset() -> void:
	ProgressManager.clear_mid_level(GameState.current_animal, GameState.current_level)
	load_level(_level_data)

func _on_back_pressed() -> void:
	ConfirmExitDialog.ask(func():
		_timer_active = false
		if puzzle_manager:
			puzzle_manager.running = false
		_save_mid_level()
		go_to_next_scene()
	)

func _on_menu_pressed() -> void:
	emit_signal("menu_pressed")
	go_to_next_scene()

func _on_next_pressed() -> void:
	if _completion_overlay:
		_completion_overlay.queue_free()
		_completion_overlay = null
	var next_id := _next_level_id(GameState.current_level)
	if next_id.is_empty():
		go_to_next_scene()
		return
	var next_data := FoxLevels.get_level(next_id)
	if next_data.is_empty():
		go_to_next_scene()
		return
	GameState.current_level = next_id
	GameState.current_par   = next_data.get("moves_par", 0)
	_resets_used = 0
	load_level(next_data)
	if puzzle_manager:
		puzzle_manager.start_level(GameState.current_animal, GameState.current_level, GameState.current_par)
	_check_all_tutorials()

func _next_level_id(current: String) -> String:
	if current == "tutorial":
		return "level_1"
	if current.begins_with("level_"):
		var n := current.trim_prefix("level_").to_int()
		if n < 10:
			return "level_%d" % (n + 1)
	return ""

# ── Callbacks del Board ───────────────────────────────────────────────────
func _on_block_on_loss_cell() -> void:
	_timer_active = false
	AudioManager.play_sfx("lose")
	_show_loss_overlay()

func _on_block_moved() -> void:
	_moves += 1
	_refresh_move_counter()
	if puzzle_manager:
		puzzle_manager.register_move()

#Esto es una vez que el haz de luz llega a su destino
func _on_beam_reached_target() -> void:
	_timer_active = false
	AudioManager.play_sfx("win")
	var par: int = _level_data.get("moves_par", 0)
	var extra    : int = max(0, _moves - par)
	var score    : int = SCORE_BASE + extra * SCORE_PENALTY
	if extra == 0:
		score += SCORE_PAR_BONUS
	# Penalización por resets: cada reset desde el 2.º resta 1 estrella al guardar
	var reset_penalty : int = max(0, _resets_used - 1)

	if puzzle_manager:
		await puzzle_manager.complete()

	ProgressManager.clear_mid_level(GameState.current_animal, GameState.current_level)
	_show_completion_overlay(score)
	emit_signal("level_completed", score)

# ── Helpers ───────────────────────────────────────────────────────────────
func _refresh_move_counter() -> void:
	var par: int = _level_data.get("moves_par", 0)
	move_counter.text = "Movs: %d / par %d" % [_moves, par]

func _refresh_reset_label() -> void:
	if not reset_btn:
		return
	if _resets_used == 0:
		reset_btn.text = "Reiniciar"
	else:
		reset_btn.text = "Reiniciar Otra vez"

func _stars_from_moves_and_resets(extra: int) -> int:
	var base := 3 if extra == 0 else (2 if extra <= 2 else 1)
	return max(1, base - max(0, _resets_used - 1))
	
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

func _show_completion_overlay(score: int) -> void:
	if _completion_overlay: _completion_overlay.queue_free()
	var scaffold := _build_overlay_scaffold(Color("#D4A843"))
	_completion_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]
	var par  : int = _level_data.get("moves_par", 0)
	var extra: int = max(0, _moves - par)
	var stars: int = _stars_from_moves_and_resets(extra)
	var stars_str := "★".repeat(stars) + "☆".repeat(3 - stars)
	_add_label(vbox, "Nivel completado", 26, Color("#7A3010"))
	_add_label(vbox, stars_str, 32, Color("#D4A843"))
	_add_label(vbox, "+%d pts" % score, 20, Color("#D4622A"))
	var next_id := _next_level_id(GameState.current_level)
	var next_text := "Siguiente nivel" if not next_id.is_empty() else "Volver al menu"
	_add_button(vbox, next_text, 16, _on_next_pressed)
	_add_button(vbox, "Menu principal", 14, _on_menu_pressed)

func _show_loss_overlay() -> void:
	if _loss_overlay: _loss_overlay.queue_free()
	var scaffold := _build_overlay_scaffold(Color("#E8C020"))
	_loss_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]
	_add_label(vbox, "Trampa", 28, Color("#7A3010"))
	_add_label(vbox, "Pisaste una celda peligrosa", 14, Color("#D4622A"), true)
	_add_button(vbox, "Reintentar", 16, _on_loss_retry_pressed)
	_add_button(vbox, "Menu principal", 14, _on_menu_pressed)

# ── Helpers de overlay ────────────────────────────────────────────────────────
func _build_overlay_scaffold(border_color: Color) -> Dictionary:
	var layer := CanvasLayer.new()
	add_child(layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.55)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color            = Color("#FBF0E9")
	pstyle.border_color        = border_color
	pstyle.border_width_left   = 3
	pstyle.border_width_right  = 3
	pstyle.border_width_top    = 3
	pstyle.border_width_bottom = 3
	pstyle.corner_radius_top_left     = 12
	pstyle.corner_radius_top_right    = 12
	pstyle.corner_radius_bottom_left  = 12
	pstyle.corner_radius_bottom_right = 12
	panel.add_theme_stylebox_override("panel", pstyle)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_top",    32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Acotar la altura al viewport para que el botón nunca quede fuera de pantalla
	# (el contenido alto, p. ej. el mini-tablero del tutorial, hace scroll en vez de desbordar)
	vbox.minimum_size_changed.connect(_clamp_overlay_scroll.bind(scroll, vbox))
	_clamp_overlay_scroll.call_deferred(scroll, vbox)

	panel.modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(panel, "modulate:a", 1.0, 0.4)

	return {"layer": layer, "vbox": vbox}

func _clamp_overlay_scroll(scroll: ScrollContainer, vbox: Control) -> void:
	if not is_instance_valid(scroll) or not is_instance_valid(vbox):
		return
	var avail : float = get_viewport().get_visible_rect().size.y - 100.0
	scroll.custom_minimum_size.y = minf(vbox.get_combined_minimum_size().y, maxf(avail, 160.0))

func _add_label(parent: Control, txt: String, fsize: int, color: Color, wrap: bool = false) -> void:
	var l := Label.new()
	l.text = txt
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(l)

func _add_button(parent: Control, txt: String, fsize: int, callback: Callable) -> void:
	var b := Button.new()
	b.text = txt
	b.add_theme_font_size_override("font_size", fsize)
	b.pressed.connect(callback)
	parent.add_child(b)

func _on_loss_retry_pressed() -> void:
	if _loss_overlay:
		_loss_overlay.queue_free()
		_loss_overlay = null
	_do_reset()

func _check_mirror_rot_tutorial() -> void:
	if not GameState.current_level.begins_with("level_"):
		return
	var n := GameState.current_level.trim_prefix("level_").to_int()
	if n < 7:
		return
	if _tutorial_overlay != null:
		return
	if FileAccess.file_exists("user://mirror_rot_v2_seen.flag"):
		_check_toggle_tutorial()
		return
	_show_mirror_rot_tutorial()

func _show_mirror_rot_tutorial() -> void:
	_timer_active = false
	var scaffold := _build_overlay_scaffold(Color("#C04080"))
	_tutorial_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]

	_add_label(vbox, "Espejo Rotatorio", 24, Color("#7A3010"))
	vbox.add_child(HSeparator.new())
	_add_label(vbox, "La flecha del espejo indica hacia dónde saldrá el haz al tocarlo.", 16, Color("#5A3010"), true)
	_add_label(vbox, "Tócalo para cambiar su dirección.\nNo puede rebotar el haz de vuelta.", 16, Color("#D4622A"), true)
	_add_label(vbox, "Gíralo a  ↓  para que el haz llegue a  ◎", 16, Color("#7A3010"), true)

	var board_scene : PackedScene = preload("res://Escenas/UI/ZORRO/Board.tscn")
	var tut_board : Node = board_scene.instantiate()
	vbox.add_child(tut_board)
	tut_board.setup({
		"size":      4,
		"beam_dir":  [0, 1],
		"cell_size": 56.0,
		"triggers":  [],
		"grid": [
			[0, 0, 0, 0],
			[3, 0, 14, 0],
			[0, 0, 0, 0],
			[0, 0, 4, 0],
		]
	})
	tut_board.beam_reached_target.connect(_on_tutorial_beam_reached)
	tut_board.mirror_flipped.connect(tut_board.simulate_beam)

	_tutorial_done_btn = Button.new()
	_tutorial_done_btn.text = "¡Entendido!"
	_tutorial_done_btn.add_theme_font_size_override("font_size", 18)
	_tutorial_done_btn.pressed.connect(_on_mirror_rot_tutorial_done)
	vbox.add_child(_tutorial_done_btn)

	await get_tree().process_frame
	tut_board.simulate_beam()

func _on_tutorial_beam_reached() -> void:
	if _tutorial_done_btn:
		_tutorial_done_btn.visible = true

func _on_mirror_rot_tutorial_done() -> void:
	var f := FileAccess.open("user://mirror_rot_v2_seen.flag", FileAccess.WRITE)
	if f:
		f.store_string("1")
		f.close()
	if _tutorial_overlay:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_tutorial_done_btn = null
	_check_toggle_tutorial()

func _on_mirror_flipped() -> void:
	_show_toast("La dirección de este espejo ha cambiado")

func _show_toast(text: String) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pstyle := StyleBoxFlat.new()
	pstyle.bg_color = Color(0.10, 0.06, 0.03, 0.88)
	pstyle.corner_radius_top_left     = 8
	pstyle.corner_radius_top_right    = 8
	pstyle.corner_radius_bottom_left  = 8
	pstyle.corner_radius_bottom_right = 8
	pstyle.content_margin_left   = 18
	pstyle.content_margin_right  = 18
	pstyle.content_margin_top    = 10
	pstyle.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", pstyle)

	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color("#FBF0E9"))
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(lbl)
	layer.add_child(panel)

	await get_tree().process_frame
	var vp   := get_viewport().get_visible_rect().size
	panel.position = Vector2((vp.x - panel.size.x) / 2.0, vp.y - 110.0)

	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.5)
	tw.tween_property(panel, "modulate:a", 0.0, 0.25)
	tw.tween_callback(layer.queue_free)

func _save_mid_level() -> void:
	if GameState.current_animal.is_empty() or GameState.current_level.is_empty():
		return
	var state = board.get_state()
	state["moves"]   = _moves
	state["elapsed"] = _elapsed
	ProgressManager.save_mid_level(GameState.current_animal, GameState.current_level, state)

# ── Sistema de tutoriales ──────────────────────────────────────────────────────

func _check_all_tutorials() -> void:
	call_deferred("_check_intro_tutorial")
	call_deferred("_check_loss_cell_tutorial")
	call_deferred("_check_mirror_rot_tutorial")

# ── Tutorial intro (nivel "tutorial") ─────────────────────────────────────────

func _check_intro_tutorial() -> void:
	if GameState.current_level != "tutorial":
		return
	if _tutorial_overlay != null:
		return
	_show_intro_tutorial()

func _show_intro_tutorial() -> void:
	_timer_active = false
	var scaffold := _build_overlay_scaffold(Color("#D4622A"))
	_tutorial_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]

	_add_label(vbox, "Cómo jugar", 24, Color("#7A3010"))
	vbox.add_child(HSeparator.new())

	_add_label(vbox, "◉  →  →  ◎", 26, Color("#D4A843"))
	_add_label(vbox, "El haz parte de ◉ y debe llegar a ◎.\nPulsa → para simular el trayecto.", 16, Color("#5A3010"), true)

	_add_label(vbox, "▣  →  □", 22, Color("#D4622A"))
	_add_label(vbox, "Arrastra bloques ▣ a huecos libres.\nLos bloques fijos ■ no se mueven.", 16, Color("#5A3010"), true)

	_add_label(vbox, "╲    ╱", 26, Color("#6A3A80"))
	_add_label(vbox, "Los espejos desvían el haz de luz :", 16, Color("#5A3010"), true)
	_add_label(vbox, "╲  convierte  →  en  ↓  (y  ↑  en  ←)", 15, Color("#6A3A80"), true)
	_add_label(vbox, "╱  convierte  →  en  ↑  (y  ↓  en  ←)", 15, Color("#6A3A80"), true)
	_add_label(vbox, "Un espejo ▣ también se puede arrastrar.", 15, Color("#5A3010"), true)

	_add_button(vbox, "¡A jugar!", 18, _on_intro_tutorial_done)

func _on_intro_tutorial_done() -> void:
	var f := FileAccess.open("user://tutorial_intro_seen.flag", FileAccess.WRITE)
	if f: f.store_string("1"); f.close()
	if _tutorial_overlay:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_tutorial_done_btn = null
	_timer_active = true

# ── Tutorial celda trampa (nivel 5+) ──────────────────────────────────────────

func _check_loss_cell_tutorial() -> void:
	if not GameState.current_level.begins_with("level_"):
		return
	var n := GameState.current_level.trim_prefix("level_").to_int()
	if n < 5:
		return
	if FileAccess.file_exists("user://loss_cell_v1_seen.flag"):
		return
	if _tutorial_overlay != null:
		return
	_show_loss_cell_tutorial()

func _show_loss_cell_tutorial() -> void:
	_timer_active = false
	var scaffold := _build_overlay_scaffold(Color("#E8C020"))
	_tutorial_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]

	_add_label(vbox, "¡Cuidado!", 24, Color("#7A3010"))
	vbox.add_child(HSeparator.new())
	_add_label(vbox, "☠", 42, Color("#E8C020"))
	_add_label(vbox, "Este nivel tiene celdas trampa.\nSi arrastras un bloque ▣ y lo dejas encima de una, perderás el nivel y tendrás que reiniciar.", 16, Color("#5A3010"), true)
	_add_label(vbox, "Planifica bien antes de mover.", 16, Color("#D4622A"), true)
	_add_button(vbox, "Entendido", 18, _on_loss_cell_tutorial_done)

func _on_loss_cell_tutorial_done() -> void:
	var f := FileAccess.open("user://loss_cell_v1_seen.flag", FileAccess.WRITE)
	if f: f.store_string("1"); f.close()
	if _tutorial_overlay:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_tutorial_done_btn = null
	_timer_active = true
	# Si estamos en nivel 7+ encadenamos los tutoriales de espejos/toggle
	if GameState.current_level.begins_with("level_"):
		var n := GameState.current_level.trim_prefix("level_").to_int()
		if n >= 7:
			_check_mirror_rot_tutorial()

# ── Tutorial toggle + bloque acción (nivel 7+, tras espejo rotatorio) ─────────

func _check_toggle_tutorial() -> void:
	if FileAccess.file_exists("user://toggle_action_v1_seen.flag"):
		return
	if _tutorial_overlay != null:
		return
	_show_toggle_tutorial()

func _show_toggle_tutorial() -> void:
	_timer_active = false
	var scaffold := _build_overlay_scaffold(Color("#4080D4"))
	_tutorial_overlay = scaffold["layer"]
	var vbox : VBoxContainer = scaffold["vbox"]

	_add_label(vbox, "Nuevas mecánicas", 24, Color("#7A3010"))
	vbox.add_child(HSeparator.new())

	_add_label(vbox, "⚡  Toggle", 22, Color("#D4A843"))
	_add_label(vbox, "El haz lo atraviesa sin bloquearse y, al hacerlo, destruye su Bloque Acción vinculado.", 16, Color("#5A3010"), true)

	_add_label(vbox, "⊗  Bloque Acción", 22, Color("#C04040"))
	_add_label(vbox, "Bloquea el paso del haz. Solo desaparece cuando el haz activa su Toggle.", 16, Color("#5A3010"), true)

	_add_label(vbox, "Primero activa el Toggle,\nluego el camino quedará libre.", 16, Color("#D4622A"), true)

	_add_button(vbox, "Entendido", 18, _on_toggle_tutorial_done)

func _on_toggle_tutorial_done() -> void:
	var f := FileAccess.open("user://toggle_action_v1_seen.flag", FileAccess.WRITE)
	if f: f.store_string("1"); f.close()
	if _tutorial_overlay:
		_tutorial_overlay.queue_free()
		_tutorial_overlay = null
	_tutorial_done_btn = null
	_timer_active = true
