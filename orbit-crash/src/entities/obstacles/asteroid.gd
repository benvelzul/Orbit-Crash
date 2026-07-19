extends RigidBody2D

# Set the minimum number of hits required to break it
@export var max_health: int = 3
var current_health: int = 0

func _ready() -> void:
	current_health = max_health
	# Ensure this node is in the "asteroids" group via code just in case
	add_to_group("asteroids")

# This function is called by the laser when a collision happens
func take_damage(amount: int) -> void:
	current_health -= amount
	print(name, " took damage! Current health: ", current_health)
	
	# If health runs out, break the asteroid
	if current_health <= 0:
		break_asteroid()

func break_asteroid() -> void:
	print(name, " broke!")
	# Safely remove the physics body at the end of the frame
	call_deferred("queue_free")
