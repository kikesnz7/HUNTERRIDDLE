extends Control

signal back_pressed
signal level_selected(level_id: int)
signal ranking_pressed

const FOX_MID  = Color("#D4622A")
const FOX_LIGHT= Color("#F2C4A8")

@onready var top_bar       = find_child("TopBar",                true, false)
@onready var levels_scroll = find_child("LevelsScrollContainer", true, false)
@onready var bottom_bar    = find_child("BottomBar",             true, false)
@onready var progress_band = find_child("ProgressBand",          true, false)
@onready var nav_inicio    = find_child("NavItem_Inicio",        true, false)
@onready var nav_niveles   = find_child("NavItem_Niveles",       true, false)
@onready var nav_ranking   = find_child("NavItem_Ranking",       true, false)

func _ready():
	await get_tree().process_frame
	_setup_scroll_signal()
	_setup_progress()
	_setup_stats()
	_setup_nav()
	_setup_levels()


func _setup_scroll_signal():
	if not levels_scroll:
		return
	levels_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

func _on_scroll_changed(value: float):
	var scroll_bar = levels_scroll.get_v_scroll_bar()
	var max_val    = scroll_bar.max_value - scroll_bar.page
	var ratio      = value / max_val if max_val > 0 else 0.0

func _setup_progress():
	if progress_band:
		progress_band.set_progress(0, "dificultad fácil")

func _setup_stats():
	var pill_c = find_child("StatPillCompletados", true, false)
	var pill_t = find_child("StatPillTiempo",      true, false)
	var pill_p = find_child("StatPillPuntos",      true, false)
	if pill_c: pill_c.set_stat("0",     "completados")
	if pill_t: pill_t.set_stat("", "mejor tiempo")
	if pill_p: pill_p.set_stat("0",   "puntos")

func _setup_nav():
	if nav_inicio:
		nav_inicio.set_active(false)
		nav_inicio.gui_input.connect(_on_nav_inicio)
	if nav_niveles:
		nav_niveles.set_active(true)
	if nav_ranking:
		nav_ranking.set_active(false)
		nav_ranking.gui_input.connect(_on_nav_ranking)

func _on_nav_inicio(event: InputEvent):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		emit_signal("back_pressed")

func _on_nav_ranking(event: InputEvent):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		emit_signal("ranking_pressed")

func _setup_levels():
	var vbox = find_child("LevelsVBox", true, false)
	if not vbox:
		return
	for card in vbox.get_children():
		if card.has_method("set_stat"):
			continue
		if card.get("state") != null and card.state != 2:
			card.gui_input.connect(_on_card_input.bind(card.level_number))

func _on_card_input(event: InputEvent, id: int):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		emit_signal("level_selected", id)
