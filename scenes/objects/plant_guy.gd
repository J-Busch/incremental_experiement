extends CharacterBody2D

enum State { IDLE, WALKING, WORKING, HELD }

const SPEED := 80.0
const WORK_INTERVAL := 1.0
const ARRIVE_DIST := 36.0
const SEEK_START_DELAY := 0.1
const SEEK_RETRY_DELAY := 1.5
const SEPARATION_SPEED := 60.0

# Prevents two overlapping NPCs from both picking up the same click.
static var _any_held: bool = false

@onready var _area: Area2D = $Area2D

var npc_id: int
var _field_origin: Vector2

var _state: State = State.IDLE
var _target_coords := Vector2i(-1, -1)
var _work_timer := 0.0
var _seek_cooldown := 0.0

func setup(id: int, field_origin: Vector2, start_held: bool = false) -> void:
	npc_id = id
	_field_origin = field_origin
	FieldManager.cell_changed.connect(_on_cell_changed)
	_area.input_event.connect(_on_area_input)
	if start_held:
		_any_held = true
		_state = State.HELD
	else:
		_seek_cooldown = SEEK_START_DELAY

func _exit_tree() -> void:
	if _state == State.HELD:
		_any_held = false

func _process(delta: float) -> void:
	velocity = Vector2.ZERO

	match _state:
		State.IDLE:
			_process_idle(delta)
		State.WALKING:
			_process_walking(delta)
		State.WORKING:
			_process_working(delta)
		State.HELD:
			_process_held()
			return

	# Apply separation from bodies we were touching last frame, then move.
	for i: int in get_slide_collision_count():
		velocity += get_slide_collision(i).get_normal() * SEPARATION_SPEED
	move_and_slide()

# ── States ───────────────────────────────────────────────────────────────────

func _process_idle(delta: float) -> void:
	_seek_cooldown -= delta
	if _seek_cooldown <= 0.0:
		_pick_next_task()

func _process_walking(delta: float) -> void:
	var target_pos := _cell_center(_target_coords)
	if position.distance_to(target_pos) <= ARRIVE_DIST:
		_state = State.WORKING
		_work_timer = WORK_INTERVAL
	else:
		velocity = (target_pos - position).normalized() * SPEED

func _process_working(delta: float) -> void:
	var cell := FieldManager.get_cell(_target_coords.x, _target_coords.y)
	match cell["type"]:
		&"boulder":
			_work_timer += delta
			if _work_timer >= WORK_INTERVAL:
				_work_timer = 0.0
				GameManager.currency += FieldManager.damage_boulder(_target_coords.x, _target_coords.y)
		&"sapling":
			FieldManager.water_sapling(_target_coords.x, _target_coords.y, delta)
		_:
			_enter_idle()

func _process_held() -> void:
	global_position = get_global_mouse_position()
	if not Input.is_action_pressed(&"LEFT_CLICK"):
		_any_held = false
		_enter_idle()

# ── Task selection ───────────────────────────────────────────────────────────

func _pick_next_task() -> void:
	var best := Vector2i(-1, -1)
	var best_dist := INF
	for coords: Vector2i in FieldManager.get_tasks():
		var cell := FieldManager.get_cell(coords.x, coords.y)
		if cell["claimed_by"].has(npc_id):
			continue
		var d := position.distance_to(_cell_center(coords))
		if d < best_dist:
			best_dist = d
			best = coords
	if best == Vector2i(-1, -1):
		_seek_cooldown = SEEK_RETRY_DELAY
		return
	_target_coords = best
	FieldManager.get_cell(best.x, best.y)["claimed_by"].append(npc_id)
	_state = State.WALKING

# ── Signal handlers ──────────────────────────────────────────────────────────

func _on_cell_changed(coords: Vector2i) -> void:
	if coords != _target_coords:
		return
	var cell := FieldManager.get_cell(coords.x, coords.y)
	if cell["type"] == &"empty" or cell["state"] == &"mature":
		_enter_idle()

func _on_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed(&"LEFT_CLICK") and _state != State.HELD and not _any_held:
		_any_held = true
		_release_claim()
		_state = State.HELD

# ── Helpers ──────────────────────────────────────────────────────────────────

func _enter_idle() -> void:
	_release_claim()
	_state = State.IDLE
	_seek_cooldown = SEEK_START_DELAY

func _release_claim() -> void:
	if _target_coords == Vector2i(-1, -1):
		return
	var cell := FieldManager.get_cell(_target_coords.x, _target_coords.y)
	cell["claimed_by"].erase(npc_id)
	_target_coords = Vector2i(-1, -1)

func _cell_center(coords: Vector2i) -> Vector2:
	return _field_origin + Vector2(
		coords.x * FieldManager.TILE_SIZE + FieldManager.TILE_SIZE * 0.5,
		coords.y * FieldManager.TILE_SIZE + FieldManager.TILE_SIZE * 0.5
	)
