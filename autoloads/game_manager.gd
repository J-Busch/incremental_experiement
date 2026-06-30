extends Node

var currency: int = 0
var inventory: Dictionary = {
	&"sapling": 5,
}

const PLACEABLE_ITEMS: Dictionary = {
	&"sapling": {
		"label": "Sapling",
		"size": Vector2i(1, 1),
		"icon": null,
	}
}

signal phase_changed(new_phase: StringName)

func go_to_world() -> void:
	phase_changed.emit(&"world")

func go_to_shop() -> void:
	phase_changed.emit(&"shop")

func add_item(item: StringName, amount: int) -> void:
	inventory[item] = inventory.get(item, 0) + amount

func remove_item(item: StringName) -> bool:
	if inventory.get(item, 0) <= 0:
		return false
	inventory[item] -= 1
	return true
