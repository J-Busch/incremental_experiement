extends Node

const SHOP_SCENE := preload("res://scenes/shop.tscn")
const GAME_WORLD_SCENE := preload("res://scenes/game_world.tscn")

var _current_scene: Node = null

@onready var _pause_menu = $PauseMenu

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.phase_changed.connect(_on_phase_changed)
	_pause_menu.reset_requested.connect(_on_reset)
	_swap_scene(SHOP_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		if _pause_menu.visible:
			_pause_menu.close()
		else:
			_pause_menu.open()
		get_viewport().set_input_as_handled()

func _on_reset() -> void:
	_swap_scene(SHOP_SCENE)

func _swap_scene(packed: PackedScene) -> void:
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = packed.instantiate()
	_current_scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_current_scene)

func _on_phase_changed(new_phase: StringName) -> void:
	match new_phase:
		&"world":
			_swap_scene(GAME_WORLD_SCENE)
		&"shop":
			_swap_scene(SHOP_SCENE)
