@tool
extends PanelContainer

@export var stat_value : String = "—"
@export var stat_label : String = ""

@onready var value_lbl : Label = $PillVBox/ValueLabel
@onready var name_lbl  : Label = $PillVBox/NameLabel

func _ready():
	value_lbl.text = stat_value
	name_lbl.text  = stat_label

func set_stat(value: String, label: String = ""):
	if label != "":
		name_lbl.text = label
	value_lbl.modulate.a = 0.0
	value_lbl.text = value
	var tween = create_tween()
	tween.tween_property(value_lbl, "modulate:a", 1.0, 0.3)\
		.set_ease(Tween.EASE_OUT)
