extends PanelContainer
class_name Cell

signal drag_started(cell: Node, cell_global_pos: Vector2)
signal toggle_requested

const FOX_BG    := Color("#FBF0E9")
const FOX_LIGHT := Color("#F2C4A8")
const FOX_MID   := Color("#D4622A")
const FOX_DARK  := Color("#7A3010")
const LOCKED_C  := Color("#9090A0")
const GOLD      := Color("#D4A843")

const EMPTY   := 0; const FIXED  := 1
const MOVABLE := 2; const ORIGIN := 3
const TARGET  := 4; const MIRROR := 5
const TOGGLE  := 6

var _row  : int = 0
var _col  : int = 0
var _type : int = EMPTY
var _toggled : bool = true
var _icon_label : Label = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_icon_label)

func setup(row: int, col: int, type: int, cell_size: float) -> void:
	_row  = row
	_col  = col
	_type = type
	custom_minimum_size = Vector2(cell_size, cell_size)
	await get_tree().process_frame
	_refresh()

func set_type(type: int) -> void:
	_type = type
	_refresh()

func toggle() -> void:
	_toggled = not _toggled
	_refresh()

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
		TOGGLE:
			if event is InputEventMouseButton:
				var e := event as InputEventMouseButton
				if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
					emit_signal("toggle_requested")
			elif event is InputEventScreenTouch:
				var e := event as InputEventScreenTouch
				if e.pressed:
					emit_signal("toggle_requested")

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
			icon = "◉"
		TARGET:
			style.bg_color     = FOX_MID
			style.border_color = FOX_MID.darkened(0.15)
			icon = "◎"
		MIRROR:
			style.bg_color     = FOX_BG
			style.border_color = FOX_MID
			icon = "╱"
		TOGGLE:
			if _toggled:
				style.bg_color     = LOCKED_C
				style.border_color = LOCKED_C.darkened(0.2)
				icon = "⊠"
			else:
				style.bg_color     = FOX_BG
				style.border_color = FOX_BG.darkened(0.08)
				icon = "⊡"
	add_theme_stylebox_override("panel", style)
	if _icon_label:
		_icon_label.text = icon
		_icon_label.add_theme_font_size_override("font_size", 18)
