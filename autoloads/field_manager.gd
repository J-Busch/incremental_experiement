extends Node

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 20
const TILE_SIZE: int = 32

var grid_data: Array = []

signal cell_changed(coords: Vector2i)

const BOULDER_ATTEMPTS: int = 400
const BOULDER_SIZES: Array = [
	Vector2i(1, 1), Vector2i(1, 1), Vector2i(1, 1),
	Vector2i(2, 1), Vector2i(1, 2),
	Vector2i(2, 2),
	Vector2i(3, 2), Vector2i(2, 3),
	Vector2i(3, 3), Vector2i(3, 3)
]
const BOULDER_HEALTH: Dictionary = {
	Vector2i(1, 1): 3,
	Vector2i(2, 1): 5,
	Vector2i(1, 2): 5,
	Vector2i(2, 2): 8,
	Vector2i(3, 2): 12,
	Vector2i(2, 3): 12,
	Vector2i(3, 3): 18
}

func _ready() -> void:
	generate()
	_debug_print_grid_stats()

func generate() -> void:
	grid_data.resize(GRID_WIDTH * GRID_HEIGHT)
	for y: int in GRID_HEIGHT:
		for x: int in GRID_WIDTH:
			grid_data[y * GRID_WIDTH + x] = _make_empty_cell(Vector2i(x, y))
	_place_boulders()

func _place_boulders() -> void:
	for _i: int in BOULDER_ATTEMPTS:
		var size: Vector2i = BOULDER_SIZES[randi() % BOULDER_SIZES.size()]
		var x := randi() % (GRID_WIDTH - size.x + 1)
		var y := randi() % (GRID_HEIGHT - size.y + 1)
		if _footprint_is_empty(x, y, size):
			_stamp_boulder(x, y, size)

func _footprint_is_empty(x: int, y: int, size: Vector2i) -> bool:
	for dy: int in size.y:
		for dx: int in size.x:
			if get_cell(x + dx, y + dy)["type"] != &"empty":
				return false
	return true

func _stamp_boulder(x: int, y: int, size: Vector2i) -> void:
	var origin := Vector2i(x, y)
	var max_health: int = BOULDER_HEALTH.get(size, 3)
	for dy: int in size.y:
		for dx: int in size.x:
			var coords := Vector2i(x + dx, y + dy)
			var is_origin := dx == 0 and dy == 0
			grid_data[coords.y * GRID_WIDTH + coords.x] = {
				"type": &"boulder",
				"state": &"intact",
				"progress": 1.0,
				"owner": origin,
				"size": size if is_origin else Vector2i(1, 1),
				"claimed_by": null,
				"extras": {"health": max_health, "max_health": max_health} if is_origin else {}
			}

func damage_boulder(x: int, y: int) -> void:
	var cell := get_cell(x, y)
	var origin: Vector2i = cell["owner"]
	var origin_cell := get_cell(origin.x, origin.y)
	origin_cell["extras"]["health"] -= 1
	origin_cell["progress"] = float(origin_cell["extras"]["health"]) / float(origin_cell["extras"]["max_health"])
	set_cell(origin.x, origin.y, origin_cell)
	if origin_cell["extras"]["health"] <= 0:
		_destroy_boulder(origin.x, origin.y, origin_cell["size"])

func _destroy_boulder(ox: int, oy: int, size: Vector2i) -> void:
	for dy: int in size.y:
		for dx: int in size.x:
			grid_data[(oy + dy) * GRID_WIDTH + (ox + dx)] = _make_empty_cell(Vector2i(ox + dx, oy + dy))
	cell_changed.emit(Vector2i(ox, oy))

func _debug_print_grid_stats() -> void:
	var empty_count := 0
	var boulder_origin_count := 0
	var boulder_cell_count := 0
	for y: int in GRID_HEIGHT:
		for x: int in GRID_WIDTH:
			var cell := get_cell(x, y)
			match cell["type"]:
				&"empty": empty_count += 1
				&"boulder":
					boulder_cell_count += 1
					if cell["owner"] == Vector2i(x, y):
						boulder_origin_count += 1
	print("Grid: %d empty, %d boulder cells (%d boulders)" % [
		empty_count, boulder_cell_count, boulder_origin_count
	])

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
