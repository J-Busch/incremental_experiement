extends Node

var currency: int = 0

signal phase_changed(new_phase: StringName)

func go_to_world() -> void:
	phase_changed.emit(&"world")

func go_to_shop() -> void:
	phase_changed.emit(&"shop")
