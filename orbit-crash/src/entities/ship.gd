extends CharacterBody2D

const MAX_SPEED = 600.0
const ACCELERATION = -600.0

# Define the peak strength of your gravity
const GRAVITY_STRENGTH = 300.0 
# Define how fast you want the gravity to cycle (higher = faster cycles)
const FREQUENCY = 2.0

var GRAVITY = 0.0
var time_passed: float = 0.0

func _physics_process(delta: float) -> void:
	# 1. Keep track of total elapsed time
	time_passed += delta
	
	# 2. Calculate the sine wave. 
	# sin() returns a value between -1 and 1. We multiply it by GRAVITY_STRENGTH.
	GRAVITY = sin(time_passed * FREQUENCY) * GRAVITY_STRENGTH
	
	# Optional: if you want gravity to only pull down (0 to 600) instead of reversing direction:
	GRAVITY = (sin(time_passed * FREQUENCY) + 1.0) * (GRAVITY_STRENGTH / 2.0)

	# 3. Handle boost
	if Input.is_action_pressed("ui_accept"):
		# Gradually add speed in the direction the ship is facing
		velocity.y += ACCELERATION * delta
	else:
		# Apply space drift friction when not boosting
		velocity.y += GRAVITY * delta

	# 4. Limit the ship's maximum speed so it doesn't accelerate infinitely
	velocity = velocity.limit_length(MAX_SPEED)

	move_and_slide()
