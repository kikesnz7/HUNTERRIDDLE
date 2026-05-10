extends PanelContainer
class_name Cell

# ── Señales ───────────────────────────────────────────────────────────────
signal drag_started(cell: Node, local_touch: Vector2)
signal drag_moved(cell: Node, global_pos: Vector2)   # ← nueva
signal drag_released(cell: Node)
signal toggle_requested

# ── Colores (mismo que Board) ─────────────────────────────────────────────
const FOX_BG    := Color("#FBF0E9")
const FOX_LIGHT := Color("#F2C4A8")
const FOX_MID   := Color("#D4622A")
const FOX_DARK  := Color("#7A3010")
const LOCKED_C  := Color("#9090A0")
const GOLD      := Color("#D4A843")

const EMPTY   := 0; const FIXED   := 1
const MOVABLE := 2; const ORIGIN  := 3
const TARGET  := 4; const MIRROR  := 5
const TOGGLE  := 6

# ── Estado ────────────────────────────────────────────────────────────────
var _row        : int     = 0
var _col        : int     = 0
var _type       : int     = EMPTY
var _toggled    : bool    = true
var _origin_pos : Vector2 = Vector2.ZERO

var _dragging       : bool = false   # ← nuevo: estamos arrastrando?
var _touch_index    : int  = -1      # ← nuevo: índice del dedo activo (-1 = mouse)

var _icon_label : Label = null

# ── Ciclo de vida ─────────────────────────────────────────────────────────
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_input(false)   # solo activo mientras se arrastra
	_icon_label = Label.new()
	_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_icon_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_icon_label)

# ── API pública ───────────────────────────────────────────────────────────
func setup(row: int, col: int, type: int, cell_size: float) -> void:
	_row  = row
	_col  = col
	_type = type
	custom_minimum_size = Vector2(cell_size, cell_size)
	await get_tree().process_frame
	_origin_pos = global_position
	_refresh()

func set_type(type: int) -> void:
	_type = type
	_refresh()

func toggle() -> void:
	_toggled = not _toggled
	_refresh()

func snap_back() -> void:
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "global_position", _origin_pos, 0.25)

# ── Input local (solo detecta el press inicial dentro de la celda) ─────────
func _gui_input(event: InputEvent) -> void:
	match _type:
		MOVABLE:
			if event is InputEventScreenTouch:
				var e := event as InputEventScreenTouch
				if e.pressed and not _dragging:
					_start_drag(e.index, e.position)
			elif event is InputEventMouseButton:
				var e := event as InputEventMouseButton
				if e.button_index == MOUSE_BUTTON_LEFT and e.pressed and not _dragging:
					_start_drag(e.button_index, e.global_position)
		TOGGLE:
			if event is InputEventScreenTouch:
				var e := event as InputEventScreenTouch
				if e.pressed:
					emit_signal("toggle_requested")
			elif event is InputEventMouseButton:
				var e := event as InputEventMouseButton
				if e.button_index == MOUSE_BUTTON_LEFT and e.pressed:
					emit_signal("toggle_requested")

# ── Input global (activo solo durante el drag) ────────────────────────────
func _input(event: InputEvent) -> void:
	if not _dragging:
		return

	# ── Movimiento ──────────────────────────────────────────────────────
	if event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if e.index == _touch_index:
			emit_signal("drag_moved", self, e.position)
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and _touch_index == -1:
		emit_signal("drag_moved", self, event.global_position)
		get_viewport().set_input_as_handled()

	# ── Release ─────────────────────────────────────────────────────────
	elif event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if not e.pressed and e.index == _touch_index:
			_end_drag()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT and not e.pressed and _touch_index == -1:
			_end_drag()
			get_viewport().set_input_as_handled()

# ── Helpers internos ──────────────────────────────────────────────────────
func _start_drag(touch_index: int, pos: Vector2) -> void:
	_dragging     = true
	_touch_index  = touch_index
	set_process_input(true)          # empieza a escuchar globalmente
	emit_signal("drag_started", self, pos)

func _end_drag() -> void:
	_dragging    = false
	_touch_index = -1
	set_process_input(false)         # deja de escuchar globalmente
	emit_signal("drag_released", self)

# ── Presentación ──────────────────────────────────────────────────────────
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
			style.bg_color     = FOX_DARK
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
