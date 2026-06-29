extends Node2D

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

func setup(cell_size: Vector2i) -> void:
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
