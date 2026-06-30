extends Node2D

const BOULDER_SCENE := preload("res://scenes/objects/boulder.tscn")

var _boulder_nodes: Dictionary = {}

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

func _spawn_boulder(x: int, y: int, cell: Dictionary) -> void:
	var boulder := BOULDER_SCENE.instantiate()
	boulder.position = Vector2(x * FieldManager.TILE_SIZE, y * FieldManager.TILE_SIZE)
	add_child(boulder)
	boulder.setup(Vector2i(x, y), cell["size"])
	_boulder_nodes[Vector2i(x, y)] = boulder

func _on_cell_changed(coords: Vector2i) -> void:
	if not _boulder_nodes.has(coords):
		return
	var cell := FieldManager.get_cell(coords.x, coords.y)
	var node: Node2D = _boulder_nodes[coords]
	if cell["type"] == &"empty":
		node.queue_free()
		_boulder_nodes.erase(coords)
	else:
		node.refresh(cell)
