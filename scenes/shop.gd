extends Control

func _ready() -> void:
	$VBoxContainer/CurrencyLabel.text = "Currency: %d" % GameManager.currency

func _on_proceed_button_pressed() -> void:
	GameManager.go_to_world()
