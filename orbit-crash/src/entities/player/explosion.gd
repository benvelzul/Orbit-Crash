extends Node2D

func _ready() -> void:
	# Access the particle child node, make it burst immediately
	$GPUParticles2D.emitting = true
	
	# Wait for the particles to finish (e.g., 1 or 2 seconds) then delete this node
	await get_tree().create_timer(1.5).timeout
	queue_free()
