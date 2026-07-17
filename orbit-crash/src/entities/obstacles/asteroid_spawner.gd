extends Node

# Link your Asteroid scene file here in the Inspector
@export var asteroid_scene: PackedScene
# Link your Player ship node here in the Inspector
@export var player: CharacterBody2D

@export var spawn_radius: float = 650.0 # Just outside a standard screen view

func _on_timer_timeout() -> void:
	if not player or not asteroid_scene:
		return
		
	# 1. Create a copy of the asteroid
	var new_asteroid = asteroid_scene.instantiate()
	
	# 2. Pick a random angle around the player
	var random_angle = randf_range(0, TAU)
	var spawn_offset = Vector2.RIGHT.rotated(random_angle) * spawn_radius
	
	# 3. Position the asteroid relative to where the player is currently flying
	new_asteroid.global_position = player.global_position + spawn_offset
	
	# 4. Add it to the world
	get_parent().add_child(new_asteroid)
