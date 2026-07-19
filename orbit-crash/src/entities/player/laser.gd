extends Area2D

@export var speed: float = 800.0
@export var lifetime: float = 2.0
@export var damage: int = 1 # How many hits this laser counts for

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += transform.x * speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroids"):
		# Check if the asteroid has the take_damage function
		if body.has_method("take_damage"):
			body.take_damage(damage)
		
		# The laser always breaks upon hitting an asteroid
		queue_free()
