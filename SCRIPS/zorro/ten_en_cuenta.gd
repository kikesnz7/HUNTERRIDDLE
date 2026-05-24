extends CanvasLayer

@onready var lista      : VBoxContainer = $MarginContainer/Panel/MarginContainer/VBoxContainer/ScrollContainer/Lista
@onready var btn_volver : Button        = $MarginContainer/Panel/MarginContainer/VBoxContainer/BtnVolver

const ZORRO_SCREEN_PATH : String = "res://Escenas/UI/ZORRO/ZorroScreen.tscn"

const TIPS := [
	{
		"icono":  "◉  →  →  ◎",
		"titulo": "El haz de luz",
		"desc":   "El haz parte de ◉ y debe llegar a ◎.\nPulsa → para simular el trayecto.\nSe propaga en línea recta hasta chocar con algo o salir del tablero.",
	},
	{
		"icono":  "▣  →  □",
		"titulo": "Bloques movibles",
		"desc":   "Arrastra los bloques ▣ a huecos libres para guiar el haz.\nLos bloques fijos ■ no se pueden mover.\nCada movimiento cuenta: menos movimientos = más estrellas.",
	},
	{
		"icono":  "╲    ╱",
		"titulo": "Espejos fijos",
		"desc":   "Los espejos desvían el haz:\n╲  convierte  →  en  ↓  (y  ↑  en  ←)\n╱  convierte  →  en  ↑  (y  ↓  en  ←)\nAlgunos espejos son movibles ▣ y también se pueden arrastrar.",
	},
	{
		"icono":  "↑  ↓  ←  →",
		"titulo": "Espejo Rotatorio",
		"desc":   "La flecha indica hacia dónde saldrá el haz al pasar por él.\nTócalo para cambiar su dirección (cicla entre ↑ ↓ ← →).\nNo puede devolver el haz hacia donde llegó: esa dirección se salta.",
	},
	{
		"icono":  "☠",
		"titulo": "Celdas trampa",
		"desc":   "Si arrastras un bloque ▣ y lo dejas sobre una celda trampa, perderás el nivel y tendrás que reiniciar desde el principio.\nPlanifica bien el orden de tus movimientos antes de arrastrar.",
	},
	{
		"icono":  "⚡  ⊗",
		"titulo": "Toggle y Bloque Acción",
		"desc":   "⚡ Toggle: el haz lo atraviesa sin bloquearse y, al hacerlo, destruye su Bloque Acción vinculado.\n⊗ Bloque Acción: bloquea completamente el paso del haz hasta que su Toggle lo elimine.\nEstrategia: diseña el recorrido para que el haz active el Toggle antes de llegar al Bloque Acción.",
	},
]

const COLOR_TITLE : Color = Color(0.478, 0.188, 0.063, 1.0)
const COLOR_ICON  : Color = Color(0.831, 0.384, 0.165, 1.0)
const COLOR_DESC  : Color = Color(0.318, 0.149, 0.039, 1.0)
const COLOR_CARD  : Color = Color(0.984, 0.941, 0.914, 1.0)
const COLOR_BORDER: Color = Color(0.831, 0.384, 0.165, 0.25)


func _ready() -> void:
	btn_volver.pressed.connect(_on_volver_pressed)
	_build_content()


func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(ZORRO_SCREEN_PATH)


func _build_content() -> void:
	for tip in TIPS:
		lista.add_child(_crear_tarjeta(tip))


func _crear_tarjeta(tip: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_CARD
	style.border_color = COLOR_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.content_margin_left   = 20
	style.content_margin_right  = 20
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	vbox.add_child(hbox)

	var lbl_icono := Label.new()
	lbl_icono.text = tip["icono"]
	lbl_icono.add_theme_font_size_override("font_size", 28)
	lbl_icono.add_theme_color_override("font_color", COLOR_ICON)
	lbl_icono.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl_icono)

	var lbl_titulo := Label.new()
	lbl_titulo.text = tip["titulo"]
	lbl_titulo.add_theme_font_size_override("font_size", 22)
	lbl_titulo.add_theme_color_override("font_color", COLOR_TITLE)
	lbl_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(lbl_titulo)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var lbl_desc := Label.new()
	lbl_desc.text = tip["desc"]
	lbl_desc.add_theme_font_size_override("font_size", 18)
	lbl_desc.add_theme_color_override("font_color", COLOR_DESC)
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl_desc)

	return panel
