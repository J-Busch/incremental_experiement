extends Node2D

const BOULDER_SCENE := preload("res://scenes/objects/boulder.tscn")
const SAPLING_SCENE := preload("res://scenes/objects/sapling.tscn")

var _boulder_nodes: Dictionary = {}
var _sapling_nodes: Dictionary = {}
var _placement_item: StringName = &""
var _hover_cell: Vector2i = Vector2i(-1, -1)
var _hover_valid: bool = false

func _ready() -> void:
	FieldManager.cell_changed.connect(_on_cell_changed)
	_build_all()

func _build_all() -> void:
	for y: int in FieldManager.GRID_HEIGHT:
		for x: int in FieldManager.GRID_WIDTH:
			var cell := FieldManager.get_cell(x, y)
			if cell["type"] != &"empty" and cell["owner"] == Vector2i(x, y):
				_spawn_visual(x, y, cell)

func _spawn_visual(x: int, y: int, cell: Dictionary) -> void:
	match cell["type"]:
		&"boulder": _spawn_boulder(x, y, cell)
		&"sapling": _spawn_sapling(x, y)

func _spawn_boulder(x: int, y: int, cell: Dictionary) -> void:
	var boulder := BOULDER_SCENE.instantiate()
	boulder.position = Vector2(x * FieldManager.TILE_SIZE, y * FieldManager.TILE_SIZE)
	add_child(boulder)
	boulder.setup(Vector2i(x, y), cell["size"])
	_boulder_nodes[Vector2i(x, y)] = boulder

func _spawn_sapling(x: int, y: int) -> void:
	var sapling := SAPLING_SCENE.instantiate()
	sapling.position = Vector2(x * FieldManager.TILE_SIZE, y * FieldManager.TILE_SIZE)
	add_child(sapling)
	sapling.setup(Vector2i(x, y))
	_sapling_nodes[Vector2i(x, y)] = sapling

func _on_cell_changed(coords: Vector2i) -> void:
	var cell := FieldManager.get_cell(coords.x, coords.y)

	if _boulder_nodes.has(coords):
		var node: Node2D = _boulder_nodes[coords]
		if cell["type"] == &"empty":
			node.queue_free()
			_boulder_nodes.erase(coords)
		else:
			node.refresh(cell)
		return

	if _sapling_nodes.has(coords):
		var node: Node2D = _sapling_nodes[coords]
		if cell["type"] == &"empty":
			node.queue_free()
			_sapling_nodes.erase(coords)
		else:
			node.refresh(cell)
		return

	if cell["type"] != &"empty" and cell["owner"] == coords:
		_spawn_visual(coords.x, coords.y, cell)

func enter_placement_mode(item: StringName) -> void:
	_placement_item = item

func exit_placement_mode() -> void:
	_placement_item = &""
	_hover_cell = Vector2i(-1, -1)
	queue_redraw()

func _process(_delta: float) -> void:
	if _placement_item == &"":
		return
	var new_cell := _get_hovered_cell()
	var item_def = GameManager.PLACEABLE_ITEMS.get(_placement_item)
	if item_def == null:
		return
	var item_size: Vector2i = item_def["size"]
	var has_stock: bool = GameManager.inventory.get(_placement_item, 0) > 0
	var valid: bool = _footprint_is_placeable(new_cell, item_size) and has_stock
	if new_cell != _hover_cell or valid != _hover_valid:
		_hover_cell = new_cell
		_hover_valid = valid
		queue_redraw()

func _draw() -> void:
	if _placement_item == &"" or not FieldManager.is_in_bounds(_hover_cell.x, _hover_cell.y):
		return
	var item_def = GameManager.PLACEABLE_ITEMS.get(_placement_item)
	if item_def == null:
		return
	var item_size: Vector2i = item_def["size"]
	var rect := Rect2(
		Vector2(_hover_cell.x * FieldManager.TILE_SIZE, _hover_cell.y * FieldManager.TILE_SIZE),
		Vector2(item_size.x * FieldManager.TILE_SIZE, item_size.y * FieldManager.TILE_SIZE)
	)
	var color := Color(0.0, 1.0, 0.0, 0.4) if _hover_valid else Color(1.0, 0.0, 0.0, 0.4)
	draw_rect(rect, color)

func _unhandled_input(event: InputEvent) -> void:
	if _placement_item == &"" or not event.is_action_pressed(&"RIGHT_CLICK"):
		return
	var item_def = GameManager.PLACEABLE_ITEMS.get(_placement_item)
	if item_def == null:
		return
	if _hover_valid and GameManager.remove_item(_placement_item):
		FieldManager.place_item(_hover_cell.x, _hover_cell.y, _placement_item)
		var item_size: Vector2i = item_def["size"]
		var still_has_stock: bool = GameManager.inventory.get(_placement_item, 0) > 0
		_hover_valid = _footprint_is_placeable(_hover_cell, item_size) and still_has_stock
		queue_redraw()

func _get_hovered_cell() -> Vector2i:
	var local_mouse := to_local(get_global_mouse_position())
	return Vector2i(int(local_mouse.x / FieldManager.TILE_SIZE), int(local_mouse.y / FieldManager.TILE_SIZE))

func _footprint_is_placeable(origin: Vector2i, size: Vector2i) -> bool:
	for dy: int in size.y:
		for dx: int in size.x:
			var cx := origin.x + dx
			var cy := origin.y + dy
			if not FieldManager.is_in_bounds(cx, cy) or FieldManager.get_cell(cx, cy)["type"] != &"empty":
				return false
	return true
