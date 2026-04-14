@tool
extends PanelContainer

enum State { DONE, UNLOCKED, LOCKED }

@export var level_number : int    = 1:
	set(v): level_number = v; _refresh()

@export var level_name   : String = "":
	set(v): level_name = v; _refresh()

@export var stars        : int    = 0:
	set(v): stars = v; _refresh()

@export var state        : State  = State.LOCKED:
	set(v): state = v; _refresh()

func _ready():
	_refresh()

func _refresh():
	var num_lbl   = find_child("NumberLabel", true, false)
	var name_lbl  = find_child("NameLabel",   true, false)
	var badge_lbl = find_child("BadgeLabel",  true, false)

	if num_lbl:
		num_lbl.text = "%02d" % level_number
	if name_lbl:
		name_lbl.text = level_name

	match state:
		State.DONE:
			_set_style(Color("#FBF0E9"), Color("#D4622A", 0.4), "completado")
			modulate.a = 1.0
			mouse_filter = MOUSE_FILTER_PASS
			if badge_lbl:
				badge_lbl.add_theme_color_override("font_color", Color("#7A3010"))
				var styleboxDn = $badge_lbl.get_theme_stylebox("normal") as StyleBoxFlat
				styleboxDn.bg_color = Color.SANDY_BROWN
		State.UNLOCKED:
			_set_style(Color("#FBF0E9"), Color("#D4622A", 0.2), "nuevo")
			modulate.a = 1.0
			mouse_filter = MOUSE_FILTER_PASS
			if badge_lbl:
				badge_lbl.add_theme_color_override("font_color", Color("#FBF0E9"))
				var styleboxUnl = $badge_lbl.get_theme_stylebox("normal") as StyleBoxFlat
				styleboxUnl.bg_color = Color.DARK_ORANGE
		State.LOCKED:
			_set_style(Color("#F4F2EF"), Color("#9090A0", 0.2), "bloqueado")
			modulate.a = 0.65
			mouse_filter = MOUSE_FILTER_IGNORE
			if badge_lbl:
				badge_lbl.add_theme_color_override("font_color", Color("#9090A0"))
				var stylebox = $badge_lbl.get_theme_stylebox("normal") as StyleBoxFlat
				stylebox.bg_color = Color.DARK_ORANGE

func _set_style(bg: Color, border: Color, badge: String):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(16)
	sb.content_margin_left   = 12
	sb.content_margin_right  = 12
	sb.content_margin_top    = 14
	sb.content_margin_bottom = 14
	add_theme_stylebox_override("panel", sb)
	var badge_lbl = find_child("BadgeLabel", true, false)
	if badge_lbl:
		badge_lbl.text = badge
