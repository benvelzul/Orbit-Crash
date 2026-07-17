extends CharacterBody2D

@export var explosion_scene: PackedScene

const MAX_SPEED = 600.0
const ACCELERATION = 800.0 

# Define the peak strength of your gravity
const GRAVITY_STRENGTH = 300.0 
# Define how fast you want the gravity to cycle (higher = faster cycles)
const FREQUENCY = 2.0
const STAR_COORD: Vector2 = Vector2(576, 600)

# --- NEW RADIAL DEATH ZONE ---
# If the ship gets closer than this many pixels to the star's center, it explodes!
# Adjust this number to match the actual visual radius of your star artwork.
const DEATH_RADIUS = 200
# ------------------------------

# --- DISTANCE & SCORE VARIABLES ---
const PIXELS_PER_METER = 70.0 
var distance_in_meters: float = 0.0
var high_score: int = 0
const SAVE_PATH = "user://save_game.cfg"
# ----------------------------------

var GRAVITY = 0.0
var time_passed: float = 0.0

var score_label: Label = null
var high_score_label: Label = null 

@onready var trail_particles: GPUParticles2D = $TrailParticles

func _ready() -> void:
	score_label = get_tree().current_scene.find_child("ScoreLabel", true, false) as Label
	high_score_label = get_tree().current_scene.find_child("HighScoreLabel", true, false) as Label
	
	load_high_score()
	update_high_score_display()

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# 1. Calculate the cycling gravity value
	GRAVITY = (sin(time_passed * FREQUENCY) + 1.0) * (GRAVITY_STRENGTH / 2.0)

	# 2. Always look at the mouse
	look_at(get_global_mouse_position())

	# 3. Calculate distance to the star
	var pixel_distance = global_position.distance_to(STAR_COORD)

	# 4. Handle Movement
	if Input.is_action_pressed("ui_accept"):
		trail_particles.emitting = true
		# Boost in the direction of the mouse
		var direction_to_mouse = global_position.direction_to(get_global_mouse_position())
		velocity += direction_to_mouse * ACCELERATION * delta
	else:
		trail_particles.emitting = false
		# Gravity pulls you straight toward the center of the star
		var direction_to_star = global_position.direction_to(STAR_COORD)
		velocity += direction_to_star * GRAVITY * delta

	# 5. Limit speed and move
	velocity = velocity.limit_length(MAX_SPEED)
	move_and_slide()
	
	# --- 6. RADIAL DEATH ZONE CHECK ---
	# If your distance is less than the death radius, you crashed into the star!
	if pixel_distance < DEATH_RADIUS:
		trigger_explosion()                                     
		
	# 7. Convert distance to meters for UI
	distance_in_meters = pixel_distance / PIXELS_PER_METER
	
	var current_score = snappy_distance()
	if score_label:
		score_label.text = str(current_score) + "m"
		
	if current_score > high_score:
		high_score = current_score
		update_high_score_display()

func snappy_distance() -> int:
	return roundi(distance_in_meters)

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroids") or body is Node2D:
		print("CRASH!")
		trigger_explosion()

func trigger_explosion() -> void:
	save_high_score()
	
	if explosion_scene:
		var instance = explosion_scene.instantiate()
		instance.global_position = global_position
		get_parent().add_child(instance)
	
	visible = false
	set_physics_process(false)
	
	await get_tree().create_timer(1.0).timeout
	reload_level()

func reload_level() -> void:
	get_tree().reload_current_scene()

func save_high_score() -> void:
	var config = ConfigFile.new()
	config.set_value("Progress", "high_score", high_score)
	var err = config.save(SAVE_PATH)

func load_high_score() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("Progress", "high_score", 0)
	else:
		high_score = 0

func update_high_score_display() -> void:
	if high_score_label:
		high_score_label.text = "Best: " + str(high_score) + "m"
