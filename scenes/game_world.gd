extends Control

const CAMERA_SPEED = 500.0

var _inventory_open: bool = false
var _in_placement_mode: bool = false

@onready var field_renderer = $FieldRenderer
@onready var inventory_menu = $Camera2D/InventoryMenu

func _ready() -> void:
	$PhaseTimer.start()

func _process(delta: float) -> void:
	var mins := int($PhaseTimer.time_left / 60.0)
	var secs := int($PhaseTimer.time_left) % 60
	$VBoxContainer/TimerLabel.text = "%2d : %02d" % [mins, secs]

	var direction := Vector2.ZERO
	if Input.is_action_pressed("RIGHT"):
		direction.x += 1
	if Input.is_action_pressed("LEFT"):
		direction.x -= 1
	if Input.is_action_pressed("DOWN"):
		direction.y += 1
	if Input.is_action_pressed("UP"):
		direction.y -= 1

	$Camera2D.position += direction * CAMERA_SPEED * delta
	$Camera2D.position.x = clamp($Camera2D.position.x, -480.0, 480.0)
	$Camera2D.position.y = clamp($Camera2D.position.y, -160.0, 800.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"OPEN_INV"):
		if _in_placement_mode:
			_exit_placement_mode()
		elif not _inventory_open:
			_open_inventory()
	elif event.is_action_released(&"OPEN_INV"):
		if _inventory_open:
			_close_inventory()
	elif event.is_action_pressed(&"ui_cancel") and _in_placement_mode:
		_exit_placement_mode()

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
