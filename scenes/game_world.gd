extends Control

const CAMERA_SPEED = 500.0

func _ready() -> void:
	$PhaseTimer.start()

func _process(delta: float) -> void:
	var mins := int($PhaseTimer.time_left / 60.0)
	var secs := int($PhaseTimer.time_left) % 60
	$VBoxContainer/TimerLabel.text = "%2d : %02d" % [mins, secs]

	var direction := Vector2.ZERO
	if Input.is_action_pressed("RIGHT"):
		direction.x += 1
	if Input.is_action_pressed("LEFT"):
		direction.x -= 1
	if Input.is_action_pressed("DOWN"):
		direction.y += 1
	if Input.is_action_pressed("UP"):
		direction.y -= 1

	$Camera2D.position += direction * CAMERA_SPEED * delta
	$Camera2D.position.x = clamp($Camera2D.position.x, -480.0, 480.0)
	$Camera2D.position.y = clamp($Camera2D.position.y, -160.0, 800.0)

func _on_phase_timer_timeout() -> void:
	GameManager.go_to_shop()
