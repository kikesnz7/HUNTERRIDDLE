# GameState.gd
# Autoload — Project > Project Settings > Autoload > "GameState"
# Ubicación: res://Scripts/Autoloads/GameState.gd
extends Node

var current_animal : String = "fox"
var current_level  : String = "level_1"
var current_par    : int    = 3

var ranking_return_scene : String = ""

var user_form_mode : String     = ""
var user_form_data : Dictionary = {}
