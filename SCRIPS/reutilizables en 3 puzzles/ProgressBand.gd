@tool
extends PanelContainer

@export var points : int = 0:
	set(v): points = v; _refresh()

@export var difficulty : String = "dificultad fácil":
	set(v): difficulty = v; _refresh()

@export var max_points : int = 1000:
	set(v): max_points = v; _refresh()

func _ready():
	_refresh()

func _refresh():
	var prog_bar = find_child("ProgressBar", true, false)
	var prog_lbl = find_child("ProgLabel",   true, false)
	var pts_lbl  = find_child("PtsLabel",    true, false)

	if prog_lbl:
		prog_lbl.text = "progreso · " + difficulty
	if pts_lbl:
		pts_lbl.text = str(points) + " pts"
	if prog_bar:
		prog_bar.max_value = max_points
		prog_bar.value = points

func set_progress(p: int, diff: String = ""):
	if diff != "":
		difficulty = diff
	var pts_lbl  = find_child("PtsLabel",  true, false)
	var prog_bar = find_child("ProgressBar", true, false)

	if pts_lbl:
		pts_lbl.text = str(p) + " pts"
	if prog_bar:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(prog_bar, "value", float(p), 0.6)\
			.set_ease(Tween.EASE_OUT)\
			.set_trans(Tween.TRANS_CUBIC)
		tween.tween_method(_update_pts, 0, p, 0.6)
	points = p

func _update_pts(value: int):
	var pts_lbl = find_child("PtsLabel", true, false)
	if pts_lbl:
		pts_lbl.text = str(value) + " pts"
