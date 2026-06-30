extends Node

var currency: int = 0
var day: int = 1
var inventory: Dictionary = {
	&"sapling": 5,
}

# ── Upgrade definitions ──────────────────────────────────────────────────────
# To add a tier: append to "tiers". To add an upgrade: add a new key.
# "base_value":   the stat value before any tiers are purchased.
# "value_format": printf string used by the shop to display the current value.
const UPGRADE_DEFS: Dictionary = {
	&"mining_damage": {
		"label": "Mining Damage",
		"base_value": 1.0,
		"value_format": "%d dmg/click",
		"tiers": [
			{"cost": 20,  "value": 2},
			{"cost": 50,  "value": 3},
			{"cost": 120, "value": 4},
		],
	},
	&"water_rate": {
		"label": "Watering Rate",
		"base_value": 1.0,
		"value_format": "%.2fx rate",
		"tiers": [
			{"cost": 15,  "value": 1.5},
			{"cost": 40,  "value": 2.25},
			{"cost": 100, "value": 3.375},
		],
	},
}

# ── Placeable / shop items ───────────────────────────────────────────────────
# "cost":       shards per purchase (omit to make an item non-purchasable).
# "base_slots": how many of this item can be bought per shop visit.
const PLACEABLE_ITEMS: Dictionary = {
	&"sapling": {
		"label": "Sapling",
		"size": Vector2i(1, 1),
		"icon": null,
		"cost": 15,
		"base_slots": 3,
	},
}

# ── VIP tiers ────────────────────────────────────────────────────────────────
# Must be in ascending threshold order.
# "slot_overrides": per-item shop slot counts that override the item's base_slots.
const VIP_TIERS: Array = [
	{"name": "Bronze", "threshold": 50,  "slot_overrides": {&"sapling": 4}},
	{"name": "Silver", "threshold": 200, "slot_overrides": {&"sapling": 4}},
	{"name": "Gold",   "threshold": 500, "slot_overrides": {&"sapling": 4}},
]

var upgrade_levels: Dictionary = {}
var total_spent: int = 0

const SAVE_PATH := "user://game.json"

signal phase_changed(new_phase: StringName)

func _ready() -> void:
	load_state()

# ── Phase transitions ────────────────────────────────────────────────────────

func reset() -> void:
	currency = 0
	day = 1
	inventory = {&"sapling": 5}
	upgrade_levels = {}
	total_spent = 0
	FieldManager.generate()
	save_state()
	FieldManager.save_grid()

func go_to_world() -> void:
	save_state()
	FieldManager.save_grid()
	phase_changed.emit(&"world")

func go_to_shop() -> void:
	day += 1
	save_state()
	FieldManager.save_grid()
	phase_changed.emit(&"shop")

# ── Purchases ────────────────────────────────────────────────────────────────

func buy_shop_item(item_id: StringName) -> bool:
	var def = PLACEABLE_ITEMS.get(item_id)
	if def == null or not def.has("cost"):
		return false
	var cost: int = def["cost"]
	if currency < cost:
		return false
	currency -= cost
	total_spent += cost
	add_item(item_id, 1)
	return true

func buy_upgrade(upgrade_id: StringName) -> bool:
	if not UPGRADE_DEFS.has(upgrade_id):
		return false
	var current_level: int = upgrade_levels.get(upgrade_id, 0)
	var tiers: Array = UPGRADE_DEFS[upgrade_id]["tiers"]
	if current_level >= tiers.size():
		return false
	var cost: int = tiers[current_level]["cost"]
	if currency < cost:
		return false
	currency -= cost
	total_spent += cost
	upgrade_levels[upgrade_id] = current_level + 1
	return true

# ── Derived stats ────────────────────────────────────────────────────────────

func get_upgrade_value(upgrade_id: StringName) -> float:
	var def: Dictionary = UPGRADE_DEFS[upgrade_id]
	var level: int = upgrade_levels.get(upgrade_id, 0)
	if level == 0:
		return float(def["base_value"])
	return float(def["tiers"][level - 1]["value"])

func get_mining_damage() -> int:
	return int(get_upgrade_value(&"mining_damage"))

func get_water_rate_multiplier() -> float:
	return get_upgrade_value(&"water_rate")

# Returns the index of the highest reached VIP tier, or -1 if none.
func get_vip_tier() -> int:
	var highest_tier: int = -1
	for i: int in VIP_TIERS.size():
		if total_spent >= VIP_TIERS[i]["threshold"]:
			highest_tier = i
	return highest_tier

func get_shop_slots(item_id: StringName) -> int:
	var def = PLACEABLE_ITEMS.get(item_id)
	if def == null:
		return 0
	var base: int = def.get("base_slots", 0)
	var tier := get_vip_tier()
	if tier < 0:
		return base
	return VIP_TIERS[tier].get("slot_overrides", {}).get(item_id, base)

# ── Inventory helpers ────────────────────────────────────────────────────────

func add_item(item: StringName, amount: int) -> void:
	inventory[item] = inventory.get(item, 0) + amount

func remove_item(item: StringName) -> bool:
	if inventory.get(item, 0) <= 0:
		return false
	inventory[item] -= 1
	return true

# ── Save / Load ──────────────────────────────────────────────────────────────

func save_state() -> void:
	var inv: Dictionary = {}
	for key in inventory:
		inv[str(key)] = inventory[key]
	var upg: Dictionary = {}
	for key in upgrade_levels:
		upg[str(key)] = upgrade_levels[key]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({
		"currency": currency,
		"day": day,
		"inventory": inv,
		"upgrade_levels": upg,
		"total_spent": total_spent,
	}))

func load_state() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed == null:
		return
	# Use .get() with current value as fallback so older save files load gracefully.
	currency = int(parsed.get("currency", currency))
	day = int(parsed.get("day", day))
	total_spent = int(parsed.get("total_spent", total_spent))
	var inv = parsed.get("inventory", null)
	if inv != null:
		inventory = {}
		for key: String in inv:
			inventory[StringName(key)] = int(inv[key])
	var upg = parsed.get("upgrade_levels", null)
	if upg != null:
		upgrade_levels = {}
		for key: String in upg:
			upgrade_levels[StringName(key)] = int(upg[key])
