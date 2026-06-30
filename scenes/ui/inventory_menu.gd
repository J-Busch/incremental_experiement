extends Panel

var selected_item: StringName = &""

@onready var item_list: VBoxContainer = $VBoxContainer/ItemList

func refresh() -> void:
	selected_item = &""
	for child in item_list.get_children():
		child.queue_free()
	for item_name: StringName in GameManager.inventory:
		_add_row(item_name)

func _add_row(item_name: StringName) -> void:
	var def = GameManager.PLACEABLE_ITEMS.get(item_name)
	if def == null:
		return
	var row := PanelContainer.new()
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if def["icon"] != null:
		icon.texture = def["icon"]

	var name_label := Label.new()
	name_label.text = def["label"]
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var count_label := Label.new()
	count_label.text = "x%d" % GameManager.inventory[item_name]

	hbox.add_child(icon)
	hbox.add_child(name_label)
	hbox.add_child(count_label)
	row.add_child(hbox)
	item_list.add_child(row)

	row.gui_input.connect(func(event: InputEvent): _on_row_input(event, item_name, row))

func _on_row_input(event: InputEvent, item_name: StringName, row: PanelContainer) -> void:
	if event.is_action_pressed(&"LEFT_CLICK"):
		selected_item = item_name
		for child in item_list.get_children():
			child.modulate = Color.WHITE
		row.modulate = Color(0.6, 1.0, 0.6)
