extends CharacterBody2D

@export var explosion_scene: PackedScene
# Drag your laser.tscn file into this slot in the Inspector!
@export var laser_scene: PackedScene 

const MAX_SPEED = 600.0
var GRAVITY_STRENGTH = 600
const ACCELERATION = 800.0 

# --- ROTATION VARIABLES ---
# Lower numbers = heavier, slower, smoother turns.
const ROTATION_SPEED = 6.0 

# --- SHOOTING VARIABLES ---
@export var fire_rate: float = 0.25 # Time between shots in seconds
var fire_timer: float = 0.0
# --------------------------

# --- GRAVITY WAVE VARIABLES ---
var base_gravity_strength: float = 300.0 # Stores your normal gravity
var wave_timer: float = 0.0
var next_wave_time: float = 5.0          # Time until the first wave (seconds)
var is_wave_active: bool = false
var wave_duration_timer: float = 0.0

@export var wave_duration: float = 5.0    # How long a gravity wave lasts
@export var wave_multiplier: float = 5.0  # How much stronger gravity gets

# Optional UI element to alert the player
var warning_label: Label = null

# Define how fast you want the gravity to cycle (higher = faster cycles)
const FREQUENCY = 2.0
const STAR_COORD: Vector2 = Vector2(576, 750)

# --- NEW RADIAL DEATH ZONE ---
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
@onready var muzzle: Marker2D = $Muzzle # Reference to the weapon barrel position

func _ready() -> void:
	score_label = get_tree().current_scene.find_child("ScoreLabel", true, false) as Label
	high_score_label = get_tree().current_scene.find_child("HighScoreLabel", true, false) as Label
	warning_label = get_tree().current_scene.find_child("WarningLabel", true, false) as Label
	
	# Clear warning text at start
	if warning_label:
		warning_label.text = ""
		
	# Save our starting gravity value
	base_gravity_strength = GRAVITY_STRENGTH
	
	load_high_score()
	update_high_score_display()

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# Keep track of shooting cool-down
	if fire_timer > 0:
		fire_timer -= delta
	
	# --- GRAVITY WAVE MANAGER ---
	if not is_wave_active:
		wave_timer += delta
		if wave_timer >= next_wave_time:
			trigger_gravity_wave()
	else:
		wave_duration_timer += delta
		if wave_duration_timer >= wave_duration:
			end_gravity_wave()
	# ----------------------------
	
	# Calculate the cycling gravity value using the dynamically altered GRAVITY_STRENGTH
	GRAVITY = (sin(time_passed * FREQUENCY) + 1.0) * (GRAVITY_STRENGTH / 2.0)
	
	# 2. Smoothly look at the mouse position
	var target_angle = global_position.angle_to_point(get_global_mouse_position())
	global_rotation = lerp_angle(global_rotation, target_angle, ROTATION_SPEED * delta)

	# 3. Calculate distance to the star
	var pixel_distance = global_position.distance_to(STAR_COORD)

	# 4. Handle Movement & Shooting simultaneously
	if Input.is_action_pressed("ui_accept"):
		trail_particles.emitting = true
		# Boost in the direction of the mouse
		var direction_to_mouse = global_position.direction_to(get_global_mouse_position())
		velocity += direction_to_mouse * ACCELERATION * delta
		
		# Shoot if the weapon cool-down is ready
		if fire_timer <= 0:
			shoot_laser()
	else:
		trail_particles.emitting = false
		# Gravity pulls you straight toward the center of the star
		var direction_to_star = global_position.direction_to(STAR_COORD)
		velocity += direction_to_star * GRAVITY * delta

	# 5. Limit speed and move
	velocity = velocity.limit_length(MAX_SPEED)
	move_and_slide()
	
	# --- 6. RADIAL DEATH ZONE CHECK ---
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

func shoot_laser() -> void:
	if laser_scene:
		var laser = laser_scene.instantiate()
		
		# Position the laser at the muzzle tip and match the current smooth rotation
		laser.global_position = muzzle.global_position
		laser.global_rotation = global_rotation
		
		get_parent().add_child(laser)
		
		# Reset the shooting weapon clock
		fire_timer = fire_rate

func snappy_distance() -> int:
	return roundi(distance_in_meters)

func trigger_gravity_wave() -> void:
	is_wave_active = true
	wave_duration_timer = 0.0
	
	GRAVITY_STRENGTH = base_gravity_strength * wave_multiplier
	
	if warning_label:
		warning_label.text = "⚠️ GRAVITY WAVE DETECTED! ⚠️"
		warning_label.add_theme_color_override("font_color", Color.RED) 
	print("A massive gravity wave hits!")

func end_gravity_wave() -> void:
	is_wave_active = false
	wave_timer = 0.0
	
	next_wave_time = randf_range(7.0, 15.0)
	GRAVITY_STRENGTH = base_gravity_strength
	
	if warning_label:
		warning_label.text = ""
	print("The gravity wave passes.")

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
