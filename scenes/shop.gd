extends Control

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var currency_label: Label = $VBoxContainer/CurrencyLabel
@onready var vip_label: Label = $VBoxContainer/VIPLabel
@onready var item_list: VBoxContainer = $VBoxContainer/ItemList
@onready var upgrade_list: VBoxContainer = $VBoxContainer/UpgradeList

var _items_bought: Dictionary = {}

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	day_label.text = "Day %d" % GameManager.day
	currency_label.text = "Shards: %d" % GameManager.currency
	_update_vip_label()
	_populate_items()
	_populate_upgrades()

func _update_vip_label() -> void:
	var tier_idx := GameManager.get_vip_tier()
	if tier_idx >= 0:
		vip_label.text = "VIP: %s  |  Total Spent: %d shards" % [
			GameManager.VIP_TIERS[tier_idx]["name"], GameManager.total_spent]
	else:
		vip_label.text = "Total Spent: %d shards" % GameManager.total_spent

func _populate_items() -> void:
	for child in item_list.get_children():
		child.free()
	for item_id: StringName in GameManager.PLACEABLE_ITEMS:
		var def: Dictionary = GameManager.PLACEABLE_ITEMS[item_id]
		if not def.has("cost"):
			continue
		item_list.add_child(_make_item_row(item_id, def))

func _make_item_row(item_id: StringName, def: Dictionary) -> HBoxContainer:
	var slots := GameManager.get_shop_slots(item_id)
	var bought: int = _items_bought.get(item_id, 0)
	var remaining := slots - bought
	var cost: int = def["cost"]
	var row := HBoxContainer.new()

	var name_lbl := Label.new()
	name_lbl.text = "%s  (%d shards each)" % [def["label"], cost]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var count_lbl := Label.new()
	count_lbl.text = "%d remaining" % remaining
	count_lbl.custom_minimum_size.x = 100.0
	row.add_child(count_lbl)

	var btn := Button.new()
	btn.text = "Buy"
	btn.disabled = remaining <= 0 or GameManager.currency < cost
	btn.pressed.connect(_on_buy_item.bind(item_id))
	row.add_child(btn)

	return row

func _on_buy_item(item_id: StringName) -> void:
	if GameManager.buy_shop_item(item_id):
		_items_bought[item_id] = _items_bought.get(item_id, 0) + 1
		call_deferred(&"_rebuild")

func _populate_upgrades() -> void:
	for child in upgrade_list.get_children():
		child.free()
	for upgrade_id: StringName in GameManager.UPGRADE_DEFS:
		upgrade_list.add_child(_make_upgrade_row(upgrade_id))

func _make_upgrade_row(upgrade_id: StringName) -> HBoxContainer:
	var def: Dictionary = GameManager.UPGRADE_DEFS[upgrade_id]
	var current_level: int = GameManager.upgrade_levels.get(upgrade_id, 0)
	var tiers: Array = def["tiers"]
	var max_tier: int = tiers.size()

	var row := HBoxContainer.new()

	var name_lbl := Label.new()
	name_lbl.text = "%s  (Tier %d/%d)" % [def["label"], current_level, max_tier]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)

	var val_lbl := Label.new()
	val_lbl.custom_minimum_size.x = 130.0
	val_lbl.text = def["value_format"] % GameManager.get_upgrade_value(upgrade_id)
	row.add_child(val_lbl)

	var btn := Button.new()
	if current_level >= max_tier:
		btn.text = "MAX"
		btn.disabled = true
	else:
		var next_cost: int = tiers[current_level]["cost"]
		btn.text = "Upgrade (%d shards)" % next_cost
		btn.disabled = GameManager.currency < next_cost
		btn.pressed.connect(_on_buy_upgrade.bind(upgrade_id))
	row.add_child(btn)

	return row

func _on_buy_upgrade(upgrade_id: StringName) -> void:
	if GameManager.buy_upgrade(upgrade_id):
		call_deferred(&"_rebuild")

func _on_proceed_button_pressed() -> void:
	GameManager.go_to_world()
