extends GridContainer
class_name Board

# ── Tipos de celda (espejo del documento de diseño) ───────────────────────
const EMPTY    := 0
const FIXED    := 1
const MOVABLE  := 2
const ORIGIN   := 3
const TARGET   := 4
const MIRROR   := 5
const TOGGLE   := 6

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

# ── Estado interno ────────────────────────────────────────────────────────
var _grid       : Array = []   # Array 2D [fila][col] de tipo int
var _size       : int   = 0
var _cells      : Array = []   # Array 2D [fila][col] de nodos Cell
var _cell_scene : PackedScene  # se asigna en _ready

# Drag & drop
var _dragging       : bool    = false
var _drag_cell      : Node    = null   # Cell origen del arrastre
var _drag_from      : Vector2i = Vector2i(-1, -1)
var _drag_offset    : Vector2 = Vector2.ZERO

# Haz activo (nodos Line2D creados al simular)
var _beam_lines     : Array   = []

# ── Ciclo de vida ─────────────────────────────────────────────────────────
func _ready() -> void:
	_cell_scene = preload("res://Escenas/UI/ZORRO/Cell.tscn")

func _process(_delta: float) -> void:
	if _dragging and _drag_cell:
		_drag_cell.global_position = get_global_mouse_position() - _drag_offset

# ── API pública ───────────────────────────────────────────────────────────
func setup(data: Dictionary) -> void:
	_size = data.get("size", 4)
	_grid = []
	for row in data["grid"]:
		_grid.append(row.duplicate())

	columns = _size
	_build_cells()

func simulate_beam() -> void:
	_clear_beam()
	var origin := _find_cell_of_type(ORIGIN)
	if origin == Vector2i(-1, -1):
		return

	# Stub temporal hasta implementar HazDeLight.gd
	var path: Array[Vector2i] = [origin]
	var current := origin
	var dir := Vector2i(1, 0)
	for i in _size * 4:
		var next := current + dir
		if next.x < 0 or next.x >= _size or next.y < 0 or next.y >= _size:
			break
		if _grid[next.x][next.y] == FIXED or _grid[next.x][next.y] == MOVABLE:
			break
		path.append(next)
		current = next
		if _grid[current.x][current.y] == TARGET:
			_draw_beam(path)
			emit_signal("beam_reached_target")
			return

	_draw_beam(path)

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
			cell.setup(r, c, _grid[r][c], cell_size)
			# Conectar señales de input del Cell
			cell.drag_started.connect(_on_cell_drag_started.bind(r, c))
			cell.drag_released.connect(_on_cell_drag_released)
			cell.toggle_requested.connect(_on_toggle_requested.bind(r, c))
			row_arr.append(cell)
		_cells.append(row_arr)

func _compute_cell_size() -> float:
	# El BoardContainer tiene ancho = viewport.x - márgenes laterales (40px c/u)
	var available := get_viewport_rect().size.x - 80.0
	return floor(available / _size)

# ── Drag & drop ───────────────────────────────────────────────────────────
func _on_cell_drag_started(cell: Node, local_touch: Vector2, row: int, col: int) -> void:
	if _grid[row][col] != MOVABLE:
		return
	_dragging    = true
	_drag_cell   = cell
	_drag_from   = Vector2i(row, col)
	_drag_offset = local_touch
	# Llevar la celda al frente visualmente
	cell.z_index = 10

func _on_cell_drag_released(cell: Node) -> void:
	if not _dragging:
		return
	_dragging = false
	cell.z_index = 0

	# Determinar celda destino por posición del mouse
	var target_pos := get_global_mouse_position()
	var dest       := _global_pos_to_grid(target_pos)

	if _is_valid_drop(dest):
		_move_block(_drag_from, dest)
	else:
		# Devolver la celda a su posición original
		_cells[_drag_from.x][_drag_from.y].snap_back()

	_drag_cell = null

func _is_valid_drop(dest: Vector2i) -> bool:
	if dest.x < 0 or dest.x >= _size or dest.y < 0 or dest.y >= _size:
		return false
	if dest == _drag_from:
		return false
	return _grid[dest.x][dest.y] == EMPTY

func _move_block(from: Vector2i, to: Vector2i) -> void:
	# Actualizar datos lógicos
	_grid[to.x][to.y]     = MOVABLE
	_grid[from.x][from.y] = EMPTY

	# Actualizar nodos visuales
	_cells[to.x][to.y].set_type(MOVABLE)
	_cells[from.x][from.y].set_type(EMPTY)

	# Devolver la celda arrastrada a su posición de grilla
	_drag_cell.snap_back()

	# Limpiar el haz anterior (el jugador deberá volver a simular)
	_clear_beam()

	emit_signal("block_moved")

# ── Toggle (dificultad difícil) ───────────────────────────────────────────
func _on_toggle_requested(row: int, col: int) -> void:
	if _grid[row][col] != TOGGLE:
		return
	# Alternar entre TOGGLE activo e EMPTY (implementación simplificada)
	# En una versión completa se usaría un sub-estado en el Cell
	var cell : Node = _cells[row][col]
	cell.toggle()
	_clear_beam()

# ── Dibujo del haz ────────────────────────────────────────────────────────
func _draw_beam(path: Array) -> void:
	if path.size() < 2:
		return

	# Convertir coordenadas de grilla a posiciones globales (centro de celda)
	var points : Array[Vector2] = []
	for coord in path:
		points.append(_grid_to_global_center(coord))

	var line := Line2D.new()
	line.width         = 3.0
	line.default_color = GOLD
	line.joint_mode    = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode   = Line2D.LINE_CAP_ROUND
	line.z_index        = 5
	add_child(line)

	# Animar el haz con Tween (aparición progresiva)
	line.points = PackedVector2Array(points)
	line.modulate.a = 0.0
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(line, "modulate:a", 1.0, 0.3)

	_beam_lines.append(line)

func _clear_beam() -> void:
	for line in _beam_lines:
		line.queue_free()
	_beam_lines.clear()

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
