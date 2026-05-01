extends Control

func _ready():
	custom_minimum_size = Vector2(4, 4)

func _draw():
	var center = size / 2
	draw_circle(center, 2.0, Color("#D4622A"))
