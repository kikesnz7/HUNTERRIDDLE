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

# Haz activo (nodos Line2D creados al simular)
var _beam_lines     : Array   = []

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
	_beam_dir = data.get("beam_dir", Vector2i(1, 0)) as Vector2i
	_grid = []
	for row in data["grid"]:
		_grid.append(row.duplicate())
	columns = _size
	_build_cells()

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
		if tipo == FIXED or tipo == MOVABLE:
			break
		# Avanza a la siguiente celda
		path.append(next)
		current = next
		# Espejo: añadir el punto y girar
		if tipo == MIRROR:
			dir = _reflect(dir)
			continue
		# Llegó al destino
		if tipo == TARGET:
			_draw_beam(path)
			emit_signal("beam_reached_target")
			return

	_draw_beam(path)
	
func _reflect(dir: Vector2i) -> Vector2i:
	# Espejo ╱ a 45°: (fila, col) → (-col, -fila) no, intercambia y niega
	# →  se convierte en ↓
	# ↓  se convierte en →
	# ←  se convierte en ↑
	# ↑  se convierte en ←
	return Vector2i(dir.y, dir.x)
	
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
			cell.toggle_requested.connect(_on_toggle_requested.bind(r, c))
			row_arr.append(cell)
		_cells.append(row_arr)

func _compute_cell_size() -> float:
	# El BoardContainer tiene ancho = viewport.x - márgenes laterales (40px c/u)
	var available := get_viewport_rect().size.x - 80.0
	return floor(available / _size)

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
	_drag_ghost.global_position = cell_global_pos
	get_parent().add_child(_drag_ghost)


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
	else:
		# No hace falta snap_back porque la celda real nunca se movió
		pass

	_drag_from = Vector2i(-1, -1)




func _is_valid_drop(dest: Vector2i) -> bool:
	if dest.x < 0 or dest.x >= _size or dest.y < 0 or dest.y >= _size:
		return false
	if dest == _drag_from:
		return false
	return _grid[dest.x][dest.y] == EMPTY

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
func _draw_beam(path: Array[Vector2i]) -> void:
	if path.size() < 2:
		return

	# Esperar un frame para que global_position de las celdas esté estable
	await get_tree().process_frame

	var line := Line2D.new()
	line.width           = 3.0
	line.default_color   = Color("#D4A843")
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
