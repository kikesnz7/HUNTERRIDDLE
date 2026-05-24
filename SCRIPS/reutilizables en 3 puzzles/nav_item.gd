@tool
extends VBoxContainer


@export var label_text : String = "inicio":
	set(v): label_text = v; _refresh()

@export var is_active : bool = false:
	set(v): is_active = v; _refresh()
	
@onready var nav_btn     : TextureButton        = find_child("NavBtn",     true, false)

const COLOR_ACTIVE   = Color("#D4622A")
const COLOR_INACTIVE = Color("#7A3010")

func _ready():
	_refresh()

func _refresh():
	var icon = find_child("NavIcon",   true, false)
	var lbl  = find_child("NavLabel",  true, false)
	var dot  = find_child("ActiveDot", true, false)

	var color = COLOR_ACTIVE if is_active else COLOR_INACTIVE

	if icon:
		icon.modulate = color
	if lbl:
		lbl.text = label_text
		lbl.add_theme_color_override("font_color", color)

	modulate.a = 1.0 if is_active else 0.35

	if dot:
		dot.visible = is_active

func set_active(value: bool):
	is_active = value
