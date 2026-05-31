# CompletionOverlay.gd
# Ubicación: res://Escenas/Puzzles/CompletionOverlay.gd
# Asignar al nodo CompletionOverlay (CanvasLayer) dentro de PuzzleScreen.tscn
#
# Árbol esperado:
# CompletionOverlay : CanvasLayer
# └─ Panel : PanelContainer
#    └─ VBox : VBoxContainer
#       ├─ TitleLabel   : Label        ← "¡Nivel completado!"
#       ├─ StarsRow     : HBoxContainer ← 3 nodos TextureRect (estrellas)
#       ├─ ScoreLabel   : Label        ← puntuación
#       ├─ TimeLabel    : Label        ← tiempo
#       └─ ButtonsRow   : HBoxContainer
#          ├─ BtnNext   : Button       ← "Siguiente nivel"
#          └─ BtnMenu   : Button       ← "Menú"
extends CanvasLayer

@onready var title_label = find_child("TitleLabel", true, false)
@onready var score_label = find_child("ScoreLabel", true, false)
@onready var time_label  = find_child("TimeLabel",  true, false)
@onready var stars_row   = find_child("StarsRow",   true, false)
@onready var btn_next    = find_child("BtnNext",    true, false)
@onready var btn_menu    = find_child("BtnMenu",    true, false)

# Colores por animal
const STAR_COLORS = {
	"fox":     Color("#D4622A"),
	"owl":     Color("#4A6FA5"),
	"dolphin": Color("#2A8B8B"),
	"raven":   Color("#6B4FA5"),
}
const STAR_OFF = Color("#E8E6E0")

func _ready():
	visible = false
	if btn_next: btn_next.pressed.connect(_on_next_pressed)
	if btn_menu: btn_menu.pressed.connect(_on_menu_pressed)

func show_result(score: int, stars: int, time: float,
				 animal_id: String, _level_id: String):
	visible = true

	if title_label: title_label.text = "¡Nivel completado!"
	if score_label: score_label.text = "%d puntos" % score
	if time_label:  time_label.text  = _fmt_time(time)

	# Pinta las estrellas
	if stars_row:
		var color_on  = STAR_COLORS.get(animal_id, Color("#D4A843"))
		var i = 0
		for star in stars_row.get_children():
			star.modulate = color_on if i < stars else STAR_OFF
			i += 1

	# Animación de entrada
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)\
		.set_ease(Tween.EASE_OUT)

	# Oculta "Siguiente" si no hay más niveles
	if btn_next:
		var order = ProgressManager.LEVEL_ORDER.get(animal_id, [])
		var idx   = order.find(GameState.current_level)
		btn_next.visible = idx < order.size() - 1

func _on_next_pressed():
	# Delega en PuzzleScreen
	get_parent().get_parent().go_to_next_level()

func _on_menu_pressed():
	get_parent().get_parent().go_to_menu()

func _fmt_time(s: float) -> String:
	if s <= 0.0: return "—"
	return "%02d:%02d" % [int(s) / 60, int(s) % 60]
