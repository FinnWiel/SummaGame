extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -500.0
const DOUBLE_JUMP_VELOCITY = -450.0  # Optional: You can make this weaker than the first jump
const DECELERATION_GROUND = 9000.0  # Near-instant deceleration on the floor
const DECELERATION_AIR = 800.0     # Gradual deceleration in the air

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_particles = preload("res://Scenes/JumpParticles.tscn")

# To ensure particles only play once during jump
var jump_particles_played = false
# Jump tracking variables
var is_double_jump = false  # To track if we've already done a double jump

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jumping logic.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# First jump on the ground
			velocity.y = JUMP_VELOCITY
			is_double_jump = false  # Reset double jump flag when on the ground
			jump_particles_played = false  # Reset the jump particle flag
		elif not is_double_jump:
			# Double jump logic
			velocity.y = DOUBLE_JUMP_VELOCITY
			is_double_jump = true  # Mark that we've done a double jump

	# Handle jump particles
	if not is_on_floor() and not jump_particles_played:
		var instance = jump_particles.instantiate()
		instance.global_position = $Marker2D.global_position
		get_parent().add_child(instance)
		
		# Start the jump particles animation
		instance.play("jump_particles")  # Make sure the animation plays on the particles
		jump_particles_played = true  # Set flag to prevent further particle instantiation

	# Get input direction: -1, 0, 1
	var direction := Input.get_axis("move_left", "move_right")
	
	# Flips sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# Play animations
	if is_on_floor():
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")
	else:
		if velocity.y < 0:
			# Jumping animation
			animated_sprite.play("jump")
		elif velocity.y > 0:
			# Falling animation
			animated_sprite.play("fall")
	
	# Apply horizontal movement
	if direction:
		velocity.x = direction * SPEED
	else:
		# Apply near-instant deceleration on the floor, gradual deceleration in the air
		var deceleration = DECELERATION_GROUND if is_on_floor() else DECELERATION_AIR
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

	# Move the character
	move_and_slide()
