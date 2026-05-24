extends PanelContainer
class_name Cell

signal drag_started(cell: Node, cell_global_pos: Vector2)
signal toggle_requested
signal rotate_requested

const FOX_BG    := Color("#FBF0E9")
const FOX_LIGHT := Color("#F2C4A8")
const FOX_MID   := Color("#D4622A")
const FOX_DARK  := Color("#7A3010")
const LOCKED_C  := Color("#9090A0")
const GOLD      := Color("#D4A843")

const EMPTY        := 0; const FIXED  := 1
const MOVABLE      := 2; const ORIGIN := 3
const TARGET       := 4; const MIRROR := 5
const TOGGLE         := 6; const ACTION_BLOCK  := 7
const LOSS_CELL      := 8; const MIRROR_SLASH  := 9
const MIRROR_H       := 10; const MIRROR_SLASH_H := 11
const MIRROR_ROT_RIGHT := 12
const MIRROR_ROT_LEFT  := 13
const MIRROR_ROT_UP    := 14
const MIRROR_ROT_DOWN  := 15

var _row         : int      = 0
var _col         : int      = 0
var _type        : int      = EMPTY
var _toggled     : bool     = true
var _beam_dir    : Vector2i = Vector2i(0, 0)
var _activated   : bool     = false
var _icon_label  : Label    = null
var _rotate_frame: int      = -1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_icon_label)

func setup(row: int, col: int, type: int, cell_size: float, toggled: bool = true) -> void:
	_row     = row
	_col     = col
	_type    = type
	_toggled = toggled
	custom_minimum_size = Vector2(cell_size, cell_size)
	await get_tree().process_frame
	_refresh()

func set_type(type: int) -> void:
	_type = type
	_refresh()

func set_beam_dir(dir: Vector2i) -> void:
	_beam_dir = dir
	_refresh()

func set_activated(val: bool) -> void:
	_activated = val
	_refresh()

func toggle() -> void:
	_toggled = not _toggled
	_refresh()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1.15, 1.15), 0.07)
	tw.tween_property(self, "scale", Vector2(1.0,  1.0),  0.08)

func _gui_input(event: InputEvent) -> void:
	match _type:
		MOVABLE:
			if event is InputEventMouseButton:
				var e := event as InputEventMouseButton
				if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
					emit_signal("drag_started", self, global_position)
			elif event is InputEventScreenTouch:
				var e := event as InputEventScreenTouch
				if e.pressed:
					emit_signal("drag_started", self, global_position)
		MIRROR_ROT_RIGHT, MIRROR_ROT_LEFT, MIRROR_ROT_UP, MIRROR_ROT_DOWN:
			var pressed := false
			if event is InputEventMouseButton:
				var e := event as InputEventMouseButton
				pressed = (e.button_index == MOUSE_BUTTON_LEFT and e.pressed)
			elif event is InputEventScreenTouch:
				var e := event as InputEventScreenTouch
				pressed = e.pressed
			if pressed:
				var frame := Engine.get_frames_drawn()
				if frame != _rotate_frame:
					_rotate_frame = frame
					emit_signal("rotate_requested")

func _refresh() -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left   = 1
	style.border_width_right  = 1
	style.border_width_top    = 1
	style.border_width_bottom = 1
	var icon := ""
	match _type:
		EMPTY:
			style.bg_color     = FOX_BG
			style.border_color = FOX_BG.darkened(0.08)
		FIXED:
			style.bg_color     = FOX_DARK
			style.border_color = FOX_DARK.darkened(0.2)
			icon = "■"
		MOVABLE:
			style.bg_color     = FOX_LIGHT
			style.border_color = FOX_MID
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "▣"
		ORIGIN:
			style.bg_color     = GOLD
			style.border_color = GOLD.darkened(0.15)
			match _beam_dir:
				Vector2i(0,  1): icon = "→"
				Vector2i(0, -1): icon = "←"
				Vector2i(1,  0): icon = "↓"
				Vector2i(-1, 0): icon = "↑"
				_:               icon = "◉"
		TARGET:
			style.bg_color     = FOX_MID
			style.border_color = FOX_MID.darkened(0.15)
			icon = "◎"
		MIRROR:
			style.bg_color     = Color("#EEF4FF")
			style.border_color = Color("#5090D0")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "╲"
		MIRROR_SLASH:
			style.bg_color     = Color("#F2EEFF")
			style.border_color = Color("#9060CC")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "╱"
		MIRROR_H:
			style.bg_color     = Color("#EEFAF0")
			style.border_color = Color("#40A060")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "╲"
		MIRROR_SLASH_H:
			style.bg_color     = Color("#FFF4E8")
			style.border_color = Color("#D08030")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "╱"
		TOGGLE:
			if _activated:
				style.bg_color     = Color("#4CAF50")
				style.border_color = Color("#2E7D32")
				icon = "✓"
			else:
				style.bg_color     = Color("#E8A020")
				style.border_color = Color("#B06010")
				icon = "⚡"
		ACTION_BLOCK:
			style.bg_color     = Color("#6B2D8B")
			style.border_color = Color("#3D1050")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "⊗"
		LOSS_CELL:
			style.bg_color     = FOX_BG
			style.border_color = Color("#E8C020")
			style.border_width_left   = 3
			style.border_width_right  = 3
			style.border_width_top    = 3
			style.border_width_bottom = 3
		MIRROR_ROT_RIGHT:
			style.bg_color     = Color("#FFF0F5")
			style.border_color = Color("#C04080")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "→"
		MIRROR_ROT_LEFT:
			style.bg_color     = Color("#FFF0F5")
			style.border_color = Color("#C04080")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "←"
		MIRROR_ROT_UP:
			style.bg_color     = Color("#FFF0F5")
			style.border_color = Color("#C04080")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "↑"
		MIRROR_ROT_DOWN:
			style.bg_color     = Color("#FFF0F5")
			style.border_color = Color("#C04080")
			style.border_width_left   = 2
			style.border_width_right  = 2
			style.border_width_top    = 2
			style.border_width_bottom = 2
			icon = "↓"
	add_theme_stylebox_override("panel", style)
	if _icon_label:
		_icon_label.text = icon
		var fsize := 18
		if _type in [ORIGIN, MIRROR, MIRROR_SLASH, MIRROR_H, MIRROR_SLASH_H]:
			fsize = 26
		elif _type == TOGGLE or _type == ACTION_BLOCK:
			fsize = 20
		elif _type in [MIRROR_ROT_RIGHT, MIRROR_ROT_LEFT, MIRROR_ROT_UP, MIRROR_ROT_DOWN]:
			fsize = 22
		_icon_label.add_theme_font_size_override("font_size", fsize)
