extends CharacterBody2D

const MAX_SPEED = 400.0
const ACCELERATION = -600.0
var GRAVITY = 300

func _physics_process(delta: float) -> void:
	# 3. Handle boost (Changed to 'is_action_pressed' for continuous holding)
	if Input.is_action_pressed("ui_accept"):
		# Gradually add speed in the direction the ship is facing
		velocity.y += ACCELERATION * delta
	else:
		# Apply space drift friction when not boosting
		velocity.y += GRAVITY * delta

	# 4. Limit the ship's maximum speed so it doesn't accelerate infinitely
	velocity = velocity.limit_length(MAX_SPEED)

	move_and_slide()
