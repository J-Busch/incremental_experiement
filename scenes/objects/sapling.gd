extends Node2D

@onready var visual: Sprite2D = $Visual
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

var grid_coords: Vector2i

# Area2D.input_event only fires on press/release, not continuous hold.
# _is_held bridges that gap so _process can water every frame while held.
var _is_held: bool = false

var _hide_timer: Timer

func _ready() -> void:
	progress_bar.hide()
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 2.0
	add_child(_hide_timer)
	_hide_timer.timeout.connect(func(): progress_bar.hide())
	area.input_event.connect(_on_area_input_event)

func setup(coords: Vector2i) -> void:
	grid_coords = coords
	var pixel_size := Vector2(FieldManager.TILE_SIZE, FieldManager.TILE_SIZE)

	visual.texture = _make_placeholder()
	visual.position = pixel_size / 2.0

	var shape := RectangleShape2D.new()
	shape.size = pixel_size
	collision_shape.shape = shape
	collision_shape.position = pixel_size / 2.0

	progress_bar.offset_left = 0.0
	progress_bar.offset_right = pixel_size.x
	progress_bar.offset_top = -14.0
	progress_bar.offset_bottom = -2.0

func refresh(cell: Dictionary) -> void:
	if cell["state"] == &"mature":
		visual.texture = _make_mature_placeholder()
		progress_bar.hide()
		_hide_timer.stop()
		# Disable _process once mature — continuous watering updates are no longer needed.
		set_process(false)

func _process(delta: float) -> void:
	if not _is_held:
		return
	if not Input.is_action_pressed(&"LEFT_CLICK"):
		_is_held = false
		return
	FieldManager.water_sapling(grid_coords.x, grid_coords.y, delta)
	var cell := FieldManager.get_cell(grid_coords.x, grid_coords.y)
	progress_bar.value = cell["progress"] * 100.0
	progress_bar.show()
	_hide_timer.start()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed(&"LEFT_CLICK"):
		_is_held = true
	elif event.is_action_released(&"LEFT_CLICK"):
		_is_held = false

func _make_mature_placeholder() -> ImageTexture:
	var size := FieldManager.TILE_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1.0, 0.85, 0.05))
	for x: int in size:
		img.set_pixel(x, 0, Color(0.6, 0.45, 0.0))
		img.set_pixel(x, size - 1, Color(0.6, 0.45, 0.0))
	for y: int in size:
		img.set_pixel(0, y, Color(0.6, 0.45, 0.0))
		img.set_pixel(size - 1, y, Color(0.6, 0.45, 0.0))
	return ImageTexture.create_from_image(img)

func _make_placeholder() -> ImageTexture:
	var size := FieldManager.TILE_SIZE
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.75, 0.2))
	for x: int in size:
		img.set_pixel(x, 0, Color(0.1, 0.4, 0.1))
		img.set_pixel(x, size - 1, Color(0.1, 0.4, 0.1))
	for y: int in size:
		img.set_pixel(0, y, Color(0.1, 0.4, 0.1))
		img.set_pixel(size - 1, y, Color(0.1, 0.4, 0.1))
	return ImageTexture.create_from_image(img)
