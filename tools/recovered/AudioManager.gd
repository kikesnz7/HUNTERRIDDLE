extends Node

const FADE_TIME := 1.2

var _player_a   : AudioStreamPlayer
var _player_b   : AudioStreamPlayer
var _sfx_player : AudioStreamPlayer
var _current    : AudioStreamPlayer
var _fade_tween : Tween = null

var _music_volume : float = 0.8
var _sfx_volume   : float = 1.0

var _streams : Dictionary = {}

func _ready() -> void:
	_player_a   = _make_player()
	_player_b   = _make_player()
	_sfx_player = _make_player()
	_player_a.volume_db = _db(_music_volume)
	_player_b.volume_db = -80.0
	_current = _player_a

	# Loop música al terminar
	_player_a.finished.connect(func(): if _current == _player_a and _player_a.stream: _player_a.play())
	_player_b.finished.connect(func(): if _current == _player_b and _player_b.stream: _player_b.play())

	_streams["menu"]   = _load_loop("res://assets David/audio/MenuSound.wav")
	_streams["puzzle"] = _load_loop("res://assets David/audio/PuzzleZorroSound.wav")
	_streams["button"] = load("res://assets David/audio/ButtonTouched.wav")
	_streams["reset"]  = load("res://assets David/audio/ResetSound.wav")
	_streams["win"]    = load("res://assets David/audio/WinLevelSound.wav")
	_streams["lose"]   = load("res://assets David/audio/LoseLevelSound.wav")

func play_menu_music() -> void:
	_crossfade_to("menu")

func play_puzzle_music() -> void:
	_crossfade_to("puzzle")

func stop_music() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(_current, "volume_db", -80.0, FADE_TIME)
	_fade_tween.tween_callback(_current.stop)

func play_sfx(name: String) -> void:
	var stream = _streams.get(name)
	if not stream:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = _db(_sfx_volume)
	_sfx_player.play()

func set_music_volume(linear: float) -> void:
	_music_volume = clamp(linear, 0.0, 1.0)
	if _current.playing:
		_current.volume_db = _db(_music_volume)

func set_sfx_volume(linear: float) -> void:
	_sfx_volume = clamp(linear, 0.0, 1.0)

func _crossfade_to(key: String) -> void:
	var stream = _streams.get(key)
	if not stream:
		return
	if _current.stream == stream and _current.playing:
		return
	var next := _player_b if _current == _player_a else _player_a
	next.stream = stream
	next.volume_db = -80.0
	next.play()
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween().set_parallel(true)
	_fade_tween.tween_property(next,     "volume_db", _db(_music_volume), FADE_TIME)
	_fade_tween.tween_property(_current, "volume_db", -80.0,              FADE_TIME)
	var prev := _current
	_current = next
	await _fade_tween.finished
	prev.stop()

func _make_player() -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	add_child(p)
	return p

func _load_loop(path: String) -> AudioStream:
	var s := load(path) as AudioStreamWAV
	if s:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	return s

func _db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))
