extends Control

const CAMERA_SPEED: float = 500.0
const CAMERA_X_LIMIT: float = 480.0
const CAMERA_Y_MIN: float = -160.0
const CAMERA_Y_MAX: float = 800.0

var _inventory_open: bool = false
var _in_placement_mode: bool = false

@onready var field_renderer = $FieldRenderer
@onready var inventory_menu = $Camera2D/InventoryMenu
@onready var _camera: Camera2D = $Camera2D
@onready var _timer_label: Label = $Camera2D/VBoxContainer/TimerLabel
@onready var _phase_timer: Timer = $PhaseTimer

func _ready() -> void:
	_phase_timer.start()

func _process(delta: float) -> void:
	var mins := int(_phase_timer.time_left / 60.0)
	var secs := int(_phase_timer.time_left) % 60
	_timer_label.text = "%2d : %02d" % [mins, secs]

	var direction := Vector2.ZERO
	if Input.is_action_pressed("RIGHT"):
		direction.x += 1
	if Input.is_action_pressed("LEFT"):
		direction.x -= 1
	if Input.is_action_pressed("DOWN"):
		direction.y += 1
	if Input.is_action_pressed("UP"):
		direction.y -= 1

	_camera.position += direction * CAMERA_SPEED * delta
	_camera.position.x = clamp(_camera.position.x, -CAMERA_X_LIMIT, CAMERA_X_LIMIT)
	_camera.position.y = clamp(_camera.position.y, CAMERA_Y_MIN, CAMERA_Y_MAX)

func _unhandled_input(event: InputEvent) -> void:
	# Tab (OPEN_INV) press: exit placement mode if active, otherwise open inventory.
	# Tab release: close inventory and enter placement if an item was selected.
	if event.is_action_pressed(&"OPEN_INV"):
		if _in_placement_mode:
			_exit_placement_mode()
		elif not _inventory_open:
			_open_inventory()
	elif event.is_action_released(&"OPEN_INV"):
		if _inventory_open:
			_close_inventory()

func _open_inventory() -> void:
	_inventory_open = true
	inventory_menu.refresh()
	inventory_menu.show()

func _close_inventory() -> void:
	_inventory_open = false
	inventory_menu.hide()
	if inventory_menu.selected_item != &"":
		_enter_placement_mode(inventory_menu.selected_item)

func _enter_placement_mode(item: StringName) -> void:
	_in_placement_mode = true
	field_renderer.enter_placement_mode(item)

func _exit_placement_mode() -> void:
	_in_placement_mode = false
	field_renderer.exit_placement_mode()

func _on_phase_timer_timeout() -> void:
	GameManager.go_to_shop()
