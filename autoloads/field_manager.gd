extends Node

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 32
const TILE_SIZE: int = 32

var grid_data: Array = []

signal cell_changed(coords: Vector2i)

func _ready() -> void:
	generate()
	print("FieldManager ready: %d cells generated" % grid_data.size())

func generate() -> void:
	grid_data.resize(GRID_WIDTH * GRID_HEIGHT)
	for y: int in GRID_HEIGHT:
		for x: int in GRID_WIDTH:
			grid_data[y * GRID_WIDTH + x] = _make_empty_cell(Vector2i(x, y))

func get_cell(x: int, y: int) -> Dictionary:
	return grid_data[y * GRID_WIDTH + x]

func set_cell(x: int, y: int, data: Dictionary) -> void:
	grid_data[y * GRID_WIDTH + x] = data
	cell_changed.emit(Vector2i(x, y))

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT

func _make_empty_cell(coords: Vector2i) -> Dictionary:
	return {
		"type": &"empty",
		"state": &"none",
		"progress": 0.0,
		"owner": coords,
		"size": Vector2i(1, 1),
		"claimed_by": null,
		"extras": {}
	}
