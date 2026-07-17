extends RigidBody2D

@export var textures: Array[Texture2D]
@export var max_distance_from_player: float = 1500.0

# Storage variable to find the player ship
var player_node: Node2D = null

func _ready() -> void:
	# Find the player in the scene tree (assuming your ship node is named "Player")
	player_node = get_tree().current_scene.find_child("Player", true, false)

	# 1. Choose a random texture
	if textures.size() > 0:
		$Sprite2D.texture = textures.pick_random()
		
	# 2. Physics setup
	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	var random_speed = randf_range(300, 500.0)
	linear_velocity = random_direction * random_speed
	angular_velocity = randf_range(-1.5, 1.5)

	# 3. Create a built-in timer to check distance periodically
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.autostart = true
	cleanup_timer.timeout.connect(_check_distance_cleanup)
	add_child(cleanup_timer)

func _check_distance_cleanup() -> void:
	if player_node:
		# Measure how far this specific asteroid is from the player
		var distance = global_position.distance_to(player_node.global_position)
		
		# If it's too far away, safely delete it from the game
		if distance > max_distance_from_player:
			queue_free()
			
