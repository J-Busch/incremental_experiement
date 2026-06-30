extends CanvasLayer

func open() -> void:
	show()
	get_tree().paused = true

func _on_reset_pressed() -> void:
	get_tree().paused = false
	GameManager.reset()
	GameManager.phase_changed.emit(&"shop")

func _on_quit_pressed() -> void:
	get_tree().quit()
