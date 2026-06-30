extends Node2D

# Maps boulder sizes to real Sprite2D textures.
# All values are null until real art is added — _make_placeholder fills in at runtime.
const TEXTURES: Dictionary = {
	Vector2i(1, 1): null,
	Vector2i(2, 1): null,
	Vector2i(1, 2): null,
	Vector2i(2, 2): null,
	Vector2i(3, 2): null,
	Vector2i(2, 3): null,
}

@onready var visual: Sprite2D = $Visual
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D
@onready var static_collision: CollisionShape2D = $StaticBody2D/CollisionShape2D
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var area: Area2D = $Area2D

var grid_coords: Vector2i
var _hide_timer: Timer

func _ready() -> void:
	progress_bar.hide()
	_hide_timer = Timer.new()
	_hide_timer.one_shot = true
	_hide_timer.wait_time = 2.0
	add_child(_hide_timer)
	_hide_timer.timeout.connect(func(): progress_bar.hide())
	area.input_event.connect(_on_area_input_event)

func setup(coords: Vector2i, cell_size: Vector2i) -> void:
	grid_coords = coords
	var pixel_size := Vector2(
		cell_size.x * FieldManager.TILE_SIZE,
		cell_size.y * FieldManager.TILE_SIZE
	)
	var tex = TEXTURES.get(cell_size)
	visual.texture = tex if tex != null else _make_placeholder(pixel_size)
	visual.position = pixel_size / 2.0

	var shape := RectangleShape2D.new()
	shape.size = pixel_size
	collision_shape.shape = shape
	collision_shape.position = pixel_size / 2.0
	static_collision.shape = shape
	static_collision.position = pixel_size / 2.0

	progress_bar.offset_left = 0.0
	progress_bar.offset_right = pixel_size.x
	progress_bar.offset_top = -14.0
	progress_bar.offset_bottom = -2.0

func refresh(cell: Dictionary) -> void:
	progress_bar.value = cell["progress"] * 100.0
	progress_bar.show()
	_hide_timer.start()

func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed(&"LEFT_CLICK"):
		GameManager.currency += FieldManager.damage_boulder(grid_coords.x, grid_coords.y)

func _make_placeholder(size_px: Vector2) -> ImageTexture:
	var img := Image.create(int(size_px.x), int(size_px.y), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.45, 0.35))
	for x: int in int(size_px.x):
		img.set_pixel(x, 0, Color(0.3, 0.2, 0.1))
		img.set_pixel(x, int(size_px.y) - 1, Color(0.3, 0.2, 0.1))
	for y: int in int(size_px.y):
		img.set_pixel(0, y, Color(0.3, 0.2, 0.1))
		img.set_pixel(int(size_px.x) - 1, y, Color(0.3, 0.2, 0.1))
	return ImageTexture.create_from_image(img)
