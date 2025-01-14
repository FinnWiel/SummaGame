extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -500.0
const DOUBLE_JUMP_VELOCITY = -450.0
const DECELERATION_GROUND = 9000.0 
const DECELERATION_AIR = 800.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_particles = preload("res://Scenes/JumpParticles.tscn")
@onready var smoke_attack = preload("res://Scenes/SmokeAttack.tscn")
@onready var attack_point: Marker2D = $AttackPoint

# To ensure particles only play once during jump
var jump_particles_played = false
# Doubleump tracking variables
var is_double_jump = false
# Attacking
var is_attacking = false


func _physics_process(delta: float) -> void:
	# Add gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta	
		
	# Get direction of movement
	var direction := Input.get_axis("move_left", "move_right")
	
	# Jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_double_jump = false  # Reset double jump when on the ground
			jump_particles_played = false
		elif not is_double_jump:
			velocity.y = DOUBLE_JUMP_VELOCITY
			is_double_jump = true

	# Jump particles
	if not is_on_floor() and not jump_particles_played:
		var instance = jump_particles.instantiate()
		instance.global_position = $Marker2D.global_position
		get_parent().add_child(instance)
		
		instance.play("jump_particles")
		jump_particles_played = true
		
	# Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		is_attacking = true
		animated_sprite.play("attack")
		shoot_projectile()
		await animated_sprite.animation_finished
		is_attacking = false

	
	# Flips sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
		
	# Play animations
	if not is_attacking:
		if is_on_floor():
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")
		else:
			if velocity.y < 0:
				animated_sprite.play("jump")
			elif velocity.y > 0:
				animated_sprite.play("fall")

	
	# Apply  movment
	if direction:
		velocity.x = direction * SPEED
	else:
		var deceleration = DECELERATION_GROUND if is_on_floor() else DECELERATION_AIR
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	move_and_slide()
	
	# Update Marker2D position based on character's facing direction
	var OFFSET = 50
	if animated_sprite.flip_h:  # If the character is facing left
		attack_point.global_position = global_position + Vector2(-OFFSET, 0)  # Move Marker2D to the left
	else:  # If the character is facing right
		attack_point.global_position = global_position + Vector2(OFFSET, 0)  # Move Marker2D to the right
	
func shoot_projectile() -> void:
	var POJECTILE_SPEED = 1000
	
	var projectile = smoke_attack.instantiate()
	projectile.global_position = $AttackPoint.global_position # Shoor from marker
	var direction = -1 if animated_sprite.flip_h else 1
	projectile.linear_velocity = Vector2(direction * POJECTILE_SPEED, 0)
	
	# Add the projectile to the scene
	get_parent().add_child(projectile)

	# Flip the projectile sprite based on direction
	var sprite = projectile.get_node("Smoke")  # Assuming "Smoke" is the name of the sprite node
	sprite.flip_h = direction < 0 
