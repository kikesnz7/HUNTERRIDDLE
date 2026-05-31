extends GridContainer
class_name Board

# ── Tipos de celda (espejo del documento de diseño) ───────────────────────
const EMPTY    := 0
const FIXED    := 1
const MOVABLE  := 2
const ORIGIN   := 3
const TARGET   := 4
const MIRROR   := 5
const TOGGLE        := 6
const ACTION_BLOCK  := 7
const LOSS_CELL      := 8
const MIRROR_SLASH   := 9
const MIRROR_H       := 10
const MIRROR_SLASH_H := 11
const MIRROR_ROT_RIGHT := 12
const MIRROR_ROT_LEFT  := 13
const MIRROR_ROT_UP    := 14
const MIRROR_ROT_DOWN  := 15

const DIR_RIGHT := Vector2i(0,  1)
const DIR_LEFT  := Vector2i(0, -1)
const DIR_DOWN  := Vector2i(1,  0)
const DIR_UP    := Vector2i(-1, 0)

# ── Colores ───────────────────────────────────────────────────────────────
const FOX_BG    := Color("#FBF0E9")
const FOX_LIGHT := Color("#F2C4A8")
const FOX_MID   := Color("#D4622A")
const FOX_DARK  := Color("#7A3010")
const FOX_MUTED := Color("#C4896F")
const LOCKED_C  := Color("#9090A0")
const GOLD      := Color("#D4A843")

# ── Señales ───────────────────────────────────────────────────────────────
signal block_moved
signal beam_reached_target
signal block_on_loss_cell
signal mirror_flipped

# ── Estado interno ────────────────────────────────────────────────────────
var _grid       : Array = []   # Array 2D [fila][col] de tipo int
var _size       : int   = 0
var _cells      : Array = []   # Array 2D [fila][col] de nodos Cell
var _cell_scene : PackedScene  # se asigna en _ready
var _beam_dir : Vector2i = Vector2i(1, 0)

# Drag & drop
var _dragging       : bool    = false
var _drag_ghost     : Panel     = null   # nodo visual que sigue al dedo
var _drag_from      : Vector2i = Vector2i(-1, -1)
var _drag_offset    : Vector2 = Vector2.ZERO

# Tamaño de celda fijo (0 = calcular desde viewport; >0 = usar este valor)
var _fixed_cell_size : float = 0.0

# Haz activo (nodos Line2D creados al simular)
var _beam_lines     : Array   = []

# Estado de toggles a restaurar en la próxima llamada a _build_cells()
var _saved_toggles  : Array   = []
# Parejas TOGGLE→ACTION_BLOCK del nivel actual
var _triggers       : Array   = []

# ── Ciclo de vida ─────────────────────────────────────────────────────────
func _ready() -> void:
	_cell_scene = preload("res://Escenas/UI/ZORRO/Cell.tscn")

func _process(_delta: float) -> void:
	if _dragging and _drag_ghost:
		_drag_ghost.global_position = get_global_mouse_position() - _drag_offset

func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
			_on_drag_released()
	elif event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		if not e.pressed:
			_on_drag_released()
# ── API pública ───────────────────────────────────────────────────────────
func setup(data: Dictionary) -> void:
	_size = data.get("size", 4)
	var bd = data.get("beam_dir", Vector2i(1, 0))
	_beam_dir = Vector2i(bd[0], bd[1]) if bd is Array else bd as Vector2i
	_fixed_cell_size = data.get("cell_size", 0.0)
	_grid = []
	for row in data["grid"]:
		_grid.append(row.duplicate())
	_saved_toggles = data.get("toggles", [])
	_triggers = data.get("triggers", [])
	# Garantiza que los ACTION_BLOCKs estén en el grid (restaura si venía de un guardado)
	for pair in _triggers:
		var ab = pair.get("action_block", [])
		if ab.size() >= 2:
			_grid[ab[0]][ab[1]] = ACTION_BLOCK
	columns = _size
	_build_cells()

# Devuelve el estado actual del tablero para guardado a mitad de nivel.
func get_state() -> Dictionary:
	return {
		"grid":     _grid.duplicate(true),
		"beam_dir": [_beam_dir.x, _beam_dir.y],
		"size":     _size,
	}

func simulate_beam() -> void:
	_clear_beam()
	var origin := _find_cell_of_type(ORIGIN)
	if origin == Vector2i(-1, -1):
		push_warning("No hay celda ORIGIN en el grid")
		return

	# Propagar el haz celda a celda
	var path : Array[Vector2i] = [origin]
	var current  := origin
	var dir      := _beam_dir

	for i in _size * _size:
		var next := current + dir
		# Salió del tablero
		if next.x < 0 or next.x >= _size or next.y < 0 or next.y >= _size:
			break
		var tipo : int = _grid[next.x][next.y]
		# Obstáculo: el haz para antes de entrar
		if tipo == FIXED or tipo == MOVABLE or tipo == ACTION_BLOCK:
			break
		# TOGGLE: el haz pasa y dispara la eliminación del ACTION_BLOCK vinculado
		if tipo == TOGGLE:
			_activate_toggle(next.x, next.y)
		# Avanza a la siguiente celda
		path.append(next)
		current = next
		# Espejo: añadir el punto y girar
		if tipo == MIRROR or tipo == MIRROR_H:
			dir = _reflect(dir)
			continue
		if tipo == MIRROR_SLASH or tipo == MIRROR_SLASH_H:
			dir = _reflect_slash(dir)
			continue
		if tipo in [MIRROR_ROT_RIGHT, MIRROR_ROT_LEFT, MIRROR_ROT_UP, MIRROR_ROT_DOWN]:
			var new_dir : Vector2i
			match tipo:
				MIRROR_ROT_RIGHT: new_dir = DIR_RIGHT
				MIRROR_ROT_LEFT:  new_dir = DIR_LEFT
				MIRROR_ROT_UP:    new_dir = DIR_UP
				MIRROR_ROT_DOWN:  new_dir = DIR_DOWN
			# No puede devolver el haz al lado por donde llegó
			if new_dir == Vector2i(-dir.x, -dir.y):
				break
			dir = new_dir
			continue
		# Llegó al destino
		if tipo == TARGET:
			await _draw_beam(path)
			emit_signal("beam_reached_target")
			return

	_draw_beam(path)
	
func _reflect(dir: Vector2i) -> Vector2i:
	# Espejo ╲: →↓  ↓→  ←↑  ↑←
	return Vector2i(dir.y, dir.x)

func _reflect_slash(dir: Vector2i) -> Vector2i:
	# Espejo ╱: →↑  ↑→  ←↓  ↓←
	return Vector2i(-dir.y, -dir.x)

func _on_cell_rotate_requested(row: int, col: int) -> void:
	var current_type : int = _grid[row][col]
	var next_type : int
	match current_type:
		MIRROR_ROT_RIGHT: next_type = MIRROR_ROT_LEFT
		MIRROR_ROT_LEFT:  next_type = MIRROR_ROT_UP
		MIRROR_ROT_UP:    next_type = MIRROR_ROT_DOWN
		MIRROR_ROT_DOWN:  next_type = MIRROR_ROT_RIGHT
		_: return
	_grid[row][col] = next_type
	_cells[row][col].set_type(next_type)
	_clear_beam()
	emit_signal("mirror_flipped")
	var cell_node = _cells[row][col]
	var tw = cell_node.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(cell_node, "scale", Vector2(1.2, 1.2), 0.07)
	tw.tween_property(cell_node, "scale", Vector2(1.0, 1.0), 0.1)

# ── Construcción del tablero ──────────────────────────────────────────────
func _build_cells() -> void:
	# Limpiar hijos previos
	for child in get_children():
		child.queue_free()
	_cells = []

	await get_tree().process_frame   # esperar a que queue_free procese

	var cell_size := _compute_cell_size()

	for r in _size:
		var row_arr := []
		for c in _size:
			var cell : Node = _cell_scene.instantiate()
			add_child(cell)
			var tog := true
			if not _saved_toggles.is_empty() and r < _saved_toggles.size() and c < _saved_toggles[r].size():
				tog = _saved_toggles[r][c]
			cell.setup(r, c, _grid[r][c], cell_size, tog)
			# Conectar señales de input del Cell
			cell.drag_started.connect(_on_cell_drag_started.bind(r, c))
			cell.rotate_requested.connect(_on_cell_rotate_requested.bind(r, c))
			row_arr.append(cell)
		_cells.append(row_arr)
	_saved_toggles = []
	var origin_pos := _find_cell_of_type(ORIGIN)
	if origin_pos != Vector2i(-1, -1):
		_cells[origin_pos.x][origin_pos.y].set_beam_dir(_beam_dir)

func _compute_cell_size() -> float:
	if _fixed_cell_size > 0.0:
		return _fixed_cell_size
	# Use the parent container's actual rendered size so the board fits regardless
	# of the screen's aspect ratio (avoids overflow on landscape desktop/tablet).
	var parent := get_parent() as Control
	if parent != null and parent.size.x > 0.0 and parent.size.y > 0.0:
		var available = min(parent.size.x, parent.size.y) - 8.0
		return floor(available / float(_size))
	return floor((get_viewport_rect().size.x - 80.0) / float(_size))

func _on_cell_drag_started(cell: Node, cell_global_pos: Vector2, row: int, col: int) -> void:
	if _grid[row][col] != MOVABLE:
		return
	_dragging  = true
	_drag_from = Vector2i(row, col)
	_drag_offset = get_global_mouse_position() - cell_global_pos
	_drag_ghost = Panel.new()
	var cell_node := _cells[row][col] as PanelContainer
	_drag_ghost.custom_minimum_size = cell_node.size
	_drag_ghost.size = cell_node.size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#F2C4A8")
	style.border_color = Color("#D4622A")
	style.border_width_left   = 2
	style.border_width_right  = 2
	style.border_width_top    = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left     = 6
	style.corner_radius_top_right    = 6
	style.corner_radius_bottom_left  = 6
	style.corner_radius_bottom_right = 6
	_drag_ghost.add_theme_stylebox_override("panel", style)
	_drag_ghost.z_index = 10
	get_parent().add_child(_drag_ghost)
	_drag_ghost.global_position = cell_global_pos

func _on_drag_released() -> void:
	if not _dragging:
		return
	_dragging = false

	# Determinar celda destino por posición actual del fantasma
	var ghost_center : Vector2 = _drag_ghost.global_position + _drag_ghost.size / 2.0
	var dest := _global_pos_to_grid(ghost_center)

	# Eliminar fantasma
	_drag_ghost.queue_free()
	_drag_ghost = null

	if _is_valid_drop(dest):
		_move_block(_drag_from, dest)
	elif _is_loss_drop(dest):
		_trigger_loss(_drag_from, dest)
	else:
		pass

	_drag_from = Vector2i(-1, -1)

func _is_valid_drop(dest: Vector2i) -> bool:
	if dest.x < 0 or dest.x >= _size or dest.y < 0 or dest.y >= _size:
		return false
	if dest == _drag_from:
		return false
	return _grid[dest.x][dest.y] == EMPTY

func _is_loss_drop(dest: Vector2i) -> bool:
	if dest.x < 0 or dest.x >= _size or dest.y < 0 or dest.y >= _size:
		return false
	if dest == _drag_from:
		return false
	return _grid[dest.x][dest.y] == LOSS_CELL

func _trigger_loss(from: Vector2i, to: Vector2i) -> void:
	_cells[to.x][to.y].set_type(MOVABLE)
	_cells[from.x][from.y].set_type(EMPTY)
	_clear_beam()
	emit_signal("block_on_loss_cell")

func _move_block(from: Vector2i, to: Vector2i) -> void:
	# Actualizar datos lógicos
	_grid[to.x][to.y]   = MOVABLE
	_grid[from.x][from.y] = EMPTY

	# Actualizar nodos visuales
	_cells[to.x][to.y].set_type(MOVABLE)
	_cells[from.x][from.y].set_type(EMPTY)

	# Limpiar el haz anterior (el jugador deberá volver a simular)
	_clear_beam()

	emit_signal("block_moved")

# ── Dibujo del haz ────────────────────────────────────────────────────────
func _draw_beam(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return

	# Esperar un frame para que global_position de las celdas esté estable
	await get_tree().process_frame

	var line := Line2D.new()
	line.width           = 3.0
	line.default_color   = GameState.beam_color
	line.joint_mode      = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode  = Line2D.LINE_CAP_ROUND
	line.end_cap_mode    = Line2D.LINE_CAP_ROUND
	line.z_index         = 5
	add_child(line)

	var points := PackedVector2Array()
	for coord in path:
		# Convertir coordenada de grilla a posición local del Board
		var cell : PanelContainer = _cells[coord.x][coord.y]
		var center : Vector2 = cell.position + cell.size / 2.0
		points.append(center)

	line.points = points
	_beam_lines.append(line)

func _clear_beam() -> void:
	for line in _beam_lines:
		if is_instance_valid(line):
			line.queue_free()
	_beam_lines.clear()

func _activate_toggle(row: int, col: int) -> void:
	_cells[row][col].set_activated(true)
	for pair in _triggers:
		var t = pair.get("toggle", [])
		if t.size() >= 2 and t[0] == row and t[1] == col:
			var ab = pair.get("action_block", [])
			if ab.size() >= 2:
				_grid[ab[0]][ab[1]] = EMPTY
				_cells[ab[0]][ab[1]].set_type(EMPTY)

func _restore_action_blocks() -> void:
	if _cells.is_empty():
		return
	for pair in _triggers:
		var t = pair.get("toggle", [])
		if t.size() >= 2:
			_cells[t[0]][t[1]].set_activated(false)
		var ab = pair.get("action_block", [])
		if ab.size() >= 2:
			_grid[ab[0]][ab[1]] = ACTION_BLOCK
			_cells[ab[0]][ab[1]].set_type(ACTION_BLOCK)
# ── Utilidades de coordenadas ─────────────────────────────────────────────
func _grid_to_global_center(coord: Vector2i) -> Vector2:
	if _cells.is_empty():
		return Vector2.ZERO
	var cell : Node = _cells[coord.x][coord.y]
	return cell.global_position + cell.size / 2.0

func _global_pos_to_grid(gpos: Vector2) -> Vector2i:
	for r in _size:
		for c in _size:
			var cell : Node = _cells[r][c]
			var rect := Rect2(cell.global_position, cell.size)
			if rect.has_point(gpos):
				return Vector2i(r, c)
	return Vector2i(-1, -1)

func _find_cell_of_type(type: int) -> Vector2i:
	for r in _size:
		for c in _size:
			if _grid[r][c] == type:
				return Vector2i(r, c)
	return Vector2i(-1, -1)
