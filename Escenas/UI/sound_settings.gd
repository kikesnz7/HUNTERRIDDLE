extends CanvasLayer

@onready var music_slider : HSlider = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/MusicRow/MusicSlider
@onready var sfx_slider   : HSlider = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/SfxRow/SfxSlider
@onready var btn_volver   : Button  = $MarginContainer/PanelBotones/MarginContainer/VBoxContainer/Volver

const CONFIG_PATH   : String = "res://Escenas/Config.tscn"
const SETTINGS_PATH : String = "user://settings.cfg"

func _ready() -> void:
	_load_settings()
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	btn_volver.pressed.connect(_on_volver_pressed)

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_slider.value = cfg.get_value("audio", "music_volume", 1.0)
		sfx_slider.value   = cfg.get_value("audio", "sfx_volume",   1.0)
	_apply_music(music_slider.value)
	_apply_sfx(sfx_slider.value)

func _on_music_changed(value: float) -> void:
	_apply_music(value)
	_save("audio", "music_volume", value)

func _on_sfx_changed(value: float) -> void:
	_apply_sfx(value)
	_save("audio", "sfx_volume", value)

func _apply_music(value: float) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(value, 0.0001, 1.0)))

func _apply_sfx(value: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(clampf(value, 0.0001, 1.0)))

func _save(section: String, key: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value(section, key, value)
	cfg.save(SETTINGS_PATH)

func _on_volver_pressed() -> void:
	get_tree().change_scene_to_file(CONFIG_PATH)
