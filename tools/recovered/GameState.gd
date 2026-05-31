# GameState.gd
# Autoload — Project > Project Settings > Autoload > "GameState"
# Ubicación: res://Scripts/Autoloads/GameState.gd
extends Node

var current_animal : String = "fox"
var current_level  : String = "level_1"
var current_par    : int    = 3

var ranking_return_scene  : String = ""
var ranking_filter_animal : String = ""

var user_form_mode : String     = ""
var user_form_data : Dictionary = {}

var beam_color : Color = Color("#D4A843")

const BEAM_OPTIONS := [
	{"key": "default", "label": "Dorado",  "color": Color("#D4A843"), "pts": 0},
	{"key": "blue",    "label": "Azul",    "color": Color("#4A9EFF"), "pts": 300},
	{"key": "red",     "label": "Rojo",    "color": Color("#FF4A4A"), "pts": 600},
	{"key": "green",   "label": "Verde",   "color": Color("#4AFF7A"), "pts": 1000},
]
