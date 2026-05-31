# ConfirmExitDialog.gd
# Autoload singleton — muestra un diálogo de confirmación antes de salir.
# Uso desde cualquier escena: ConfirmExitDialog.ask(func(): <acción al confirmar>)
extends CanvasLayer

var _on_confirm : Callable

var _btn_salir    : Button
var _btn_cancelar : Button

func _ready() -> void:
	layer   = 10
	visible = false
	_build_ui()

# ─── API pública ──────────────────────────────────────────────────────────────

func ask(on_confirm: Callable) -> void:
	_on_confirm = on_confirm
	visible     = true
	_animate_in()

# ─── Construcción de la UI ────────────────────────────────────────────────────

func _build_ui() -> void:
	# Control raíz: absorbe clics para que no lleguen a la escena de fondo
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Fondo oscuro semitransparente
	var bg := ColorRect.new()
	bg.color        = Color(0.1, 0.1, 0.1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)

	# CenterContainer para centrar el panel en pantalla
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	root.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Panel del diálogo
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color              = Color("#FBF0E9")
	sb.border_color          = Color(0.831, 0.384, 0.165, 0.4)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(14)
	sb.content_margin_left   = 20
	sb.content_margin_right  = 20
	sb.content_margin_top    = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)

	# Contenido vertical
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Título
	var lbl := Label.new()
	lbl.text                 = "¿Quieres salir?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color("#7A3010"))
	lbl.add_theme_font_size_override("font_size", 18)
	var font = load("res://fonts/Playfair_Display/static/PlayfairDisplay-Regular.ttf")
	if font:
		lbl.add_theme_font_override("font", font)
	vbox.add_child(lbl)

	# Fila de botones
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(hbox)

	_btn_cancelar = _make_btn("Cancelar", Color("#EDE8E3"), Color("#7A3010"), false)
	_btn_cancelar.pressed.connect(_on_cancelar_pressed)
	hbox.add_child(_btn_cancelar)

	_btn_salir = _make_btn("Salir", Color("#D4622A"), Color("#FFFFFF"), true)
	_btn_salir.pressed.connect(_on_salir_pressed)
	hbox.add_child(_btn_salir)

func _make_btn(label: String, bg: Color, fg: Color, primary: bool) -> Button:
	var btn := Button.new()
	btn.text                 = label
	btn.custom_minimum_size  = Vector2(110, 40)

	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color = bg
	sb_n.set_corner_radius_all(10)
	sb_n.content_margin_left   = 8
	sb_n.content_margin_right  = 8
	sb_n.content_margin_top    = 8
	sb_n.content_margin_bottom = 8
	if not primary:
		sb_n.border_color = Color(0.831, 0.384, 0.165, 0.3)
		sb_n.set_border_width_all(1)

	var sb_h := sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = bg.lightened(0.08)

	var sb_p := sb_n.duplicate() as StyleBoxFlat
	sb_p.bg_color = bg.darkened(0.1)

	btn.add_theme_stylebox_override("normal",  sb_n)
	btn.add_theme_stylebox_override("hover",   sb_h)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_color_override("font_color",         fg)
	btn.add_theme_color_override("font_hover_color",   fg)
	btn.add_theme_color_override("font_pressed_color", fg)
	btn.add_theme_font_size_override("font_size", 14)

	return btn

# ─── Animación ────────────────────────────────────────────────────────────────

func _animate_in() -> void:
	modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(self, "modulate:a", 1.0, 0.25)

# ─── Callbacks ────────────────────────────────────────────────────────────────

func _on_salir_pressed() -> void:
	visible = false
	_on_confirm.call()

func _on_cancelar_pressed() -> void:
	visible = false
