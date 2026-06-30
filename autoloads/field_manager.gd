extends Node

const GRID_WIDTH: int = 32
const GRID_HEIGHT: int = 20
const TILE_SIZE: int = 32

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

const SAPLING_MAX_MATURITY: float = 100.0
const SAPLING_WATER_RATE: float = 10.0

const SAVE_PATH := "user://field.json"

# Each cell in grid_data is a Dictionary with these keys:
#   type:       StringName  — &"empty", &"boulder", or &"sapling"
#   state:      StringName  — type-specific (&"intact"; &"seedling" / &"mature")
#   progress:   float       — 0.0–1.0, drives progress bars
#   owner:      Vector2i    — origin cell coords; non-origin cells point back here
#   size:       Vector2i    — footprint size, only meaningful on the origin cell
#   claimed_by: Array[int]  — NPC IDs working this tile; max MAX_WORKERS_PER_TILE
#   extras:     Dictionary  — type-specific data (boulder: health; sapling: maturity)

const MAX_WORKERS_PER_TILE: int = 5
const CARDINAL_OFFSETS: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
var grid_data: Array = []

signal cell_changed(coords: Vector2i)

# ── Lifecycle ────────────────────────────────────────────────────────────────

func _ready() -> void:
	load_or_generate()

func load_or_generate() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		_load_grid()
	else:
		generate()

# ── Grid generation ──────────────────────────────────────────────────────────

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
				"claimed_by": [],
				"extras": {"health": max_health, "max_health": max_health} if is_origin else {}
			}

# ── Boulder actions ──────────────────────────────────────────────────────────

func damage_boulder(x: int, y: int) -> int:
	var cell := get_cell(x, y)
	var origin: Vector2i = cell["owner"]
	var origin_cell := get_cell(origin.x, origin.y)
	if origin_cell["extras"]["health"] <= 0:
		return 0
	# Cap damage so we never deal more than the remaining health (avoids overkill currency).
	var damage: int = mini(GameManager.get_mining_damage(), origin_cell["extras"]["health"])
	origin_cell["extras"]["health"] -= damage
	origin_cell["progress"] = float(origin_cell["extras"]["health"]) / float(origin_cell["extras"]["max_health"])
	set_cell(origin.x, origin.y, origin_cell)
	if origin_cell["extras"]["health"] <= 0:
		_destroy_boulder(origin.x, origin.y, origin_cell["size"])
	return damage

func _destroy_boulder(ox: int, oy: int, size: Vector2i) -> void:
	for dy: int in size.y:
		for dx: int in size.x:
			grid_data[(oy + dy) * GRID_WIDTH + (ox + dx)] = _make_empty_cell(Vector2i(ox + dx, oy + dy))
	# Emit for every tile so NPCs assigned to non-origin tiles also hear the signal.
	for dy: int in size.y:
		for dx: int in size.x:
			cell_changed.emit(Vector2i(ox + dx, oy + dy))

# ── Sapling actions ──────────────────────────────────────────────────────────

func water_sapling(x: int, y: int, delta: float) -> void:
	var cell := get_cell(x, y)
	var origin: Vector2i = cell["owner"]
	var origin_cell := get_cell(origin.x, origin.y)
	if origin_cell["state"] != &"seedling":
		return
	origin_cell["extras"]["maturity"] = minf(
		origin_cell["extras"]["maturity"] + SAPLING_WATER_RATE * GameManager.get_water_rate_multiplier() * delta,
		origin_cell["extras"]["max_maturity"]
	)
	origin_cell["progress"] = origin_cell["extras"]["maturity"] / origin_cell["extras"]["max_maturity"]
	# cell_changed is only emitted on the maturity transition, not every frame.
	# The sapling visual reads progress directly in _process while watering.
	if origin_cell["extras"]["maturity"] >= origin_cell["extras"]["max_maturity"]:
		origin_cell["state"] = &"mature"
		set_cell(origin.x, origin.y, origin_cell)

# ── Item placement ───────────────────────────────────────────────────────────

func place_item(x: int, y: int, item: StringName) -> bool:
	var item_def = GameManager.PLACEABLE_ITEMS.get(item)
	if item_def == null:
		return false
	var size: Vector2i = item_def["size"]
	for dy: int in size.y:
		for dx: int in size.x:
			if not is_in_bounds(x + dx, y + dy) or get_cell(x + dx, y + dy)["type"] != &"empty":
				return false
	var origin := Vector2i(x, y)
	for dy: int in size.y:
		for dx: int in size.x:
			var is_origin := dx == 0 and dy == 0
			set_cell(x + dx, y + dy, {
				"type": item,
				"state": &"seedling",
				"progress": 0.0,
				"owner": origin,
				"size": size if is_origin else Vector2i(1, 1),
				"claimed_by": [],
				"extras": {"maturity": 0.0, "max_maturity": SAPLING_MAX_MATURITY} if is_origin else {}
			})
	return true

# ── Grid accessors ───────────────────────────────────────────────────────────

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
		"claimed_by": [],
		"extras": {}
	}

# ── NPC helpers ──────────────────────────────────────────────────────────────

# Returns all tile coords available for NPC work: boulders and seedling saplings
# with fewer than MAX_WORKERS_PER_TILE current claimants.
func get_tasks() -> Array:
	var result: Array = []
	for y: int in GRID_HEIGHT:
		for x: int in GRID_WIDTH:
			var cell := get_cell(x, y)
			if cell["type"] == &"empty":
				continue
			if cell["claimed_by"].size() >= MAX_WORKERS_PER_TILE:
				continue
			var is_workable: bool = (
				(cell["type"] == &"boulder" and cell["state"] == &"intact")
				or (cell["type"] == &"sapling" and cell["state"] == &"seedling")
			)
			if is_workable and _is_exterior_tile(x, y):
				result.append(Vector2i(x, y))
	return result

# A tile is exterior if at least one cardinal neighbor is empty or out of bounds,
# meaning an NPC can reach it from that direction without crossing the physics body.
func _is_exterior_tile(x: int, y: int) -> bool:
	for offset: Vector2i in CARDINAL_OFFSETS:
		var nx := x + offset.x
		var ny := y + offset.y
		if not is_in_bounds(nx, ny) or get_cell(nx, ny)["type"] == &"empty":
			return true
	return false

func has_boulders() -> bool:
	for cell: Dictionary in grid_data:
		if cell["type"] == &"boulder":
			return true
	return false

func harvest_sapling(x: int, y: int) -> void:
	var cell := get_cell(x, y)
	if cell["type"] != &"sapling" or cell["state"] != &"mature":
		return
	set_cell(x, y, _make_empty_cell(Vector2i(x, y)))

# ── Save / Load ──────────────────────────────────────────────────────────────

func save_grid() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_serialize_grid()))

func _serialize_grid() -> Array:
	var result: Array = []
	for cell in grid_data:
		result.append({
			"type": str(cell["type"]),
			"state": str(cell["state"]),
			"progress": cell["progress"],
			"owner": "%d,%d" % [cell["owner"].x, cell["owner"].y],
			"size": "%d,%d" % [cell["size"].x, cell["size"].y],
			"claimed_by": [],
			"extras": cell["extras"].duplicate()
		})
	return result

func _load_grid() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		generate()
		return
	grid_data.resize(GRID_WIDTH * GRID_HEIGHT)
	for i: int in parsed.size():
		var d: Dictionary = parsed[i]
		grid_data[i] = {
			"type": StringName(d["type"]),
			"state": StringName(d["state"]),
			"progress": float(d["progress"]),
			"owner": _str_to_vec2i(d["owner"]),
			"size": _str_to_vec2i(d["size"]),
			"claimed_by": [],
			"extras": d["extras"].duplicate()
		}

func _str_to_vec2i(s: String) -> Vector2i:
	var parts := s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
