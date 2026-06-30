extends CanvasLayer

signal reset_requested

func _ready() -> void:
	hide()

func open() -> void:
	show()
	get_tree().paused = true

func close() -> void:
	hide()
	get_tree().paused = false

func _on_resume_pressed() -> void:
	close()

func _on_reset_pressed() -> void:
	close()
	GameManager.reset()
	reset_requested.emit()

func _on_quit_pressed() -> void:
	get_tree().quit()
