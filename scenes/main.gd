extends Node

const SHOP_SCENE := preload("res://scenes/shop.tscn")
const GAME_WORLD_SCENE := preload("res://scenes/game_world.tscn")

var _current_scene: Node = null

func _ready() -> void:
	GameManager.phase_changed.connect(_on_phase_changed)
	_swap_scene(SHOP_SCENE)

func _swap_scene(packed: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = packed.instantiate()
	add_child(_current_scene)

func _on_phase_changed(new_phase: StringName) -> void:
	match new_phase:
		&"world":
			_swap_scene(GAME_WORLD_SCENE)
		&"shop":
			_swap_scene(SHOP_SCENE)
