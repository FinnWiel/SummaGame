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
@onready var game_ui: Node2D = $"../UI/GameUI"

var jump_particles_played = false
var is_double_jump = false # Doubleump tracking variables
var is_attacking = false

# Hitpoints
var MAX_HP = 3
var HP = MAX_HP 
var HPS = 1


# Magicpoints
var MAX_MP: float= 3
var MP: float = MAX_MP
var MPS: float = 1
var MP_COST: float = 1

var time_accumulated: float = 0.0

func _process(delta: float) -> void:
	time_accumulated += delta
	update_ui()
	if time_accumulated >= 1.0:
		time_accumulated -= 1.0
		if MP < MAX_MP:
			MP += MPS
		
func update_ui() -> void:
	var mana_container = game_ui.get_node("VBox/Mana")
	var health_container = game_ui.get_node("VBox/Health")
	
	# Clear existing icons to prevent duplication
	for child in mana_container.get_children():
		mana_container.remove_child(child)
		child.queue_free()
	
	for child in health_container.get_children():
		health_container.remove_child(child)
		child.queue_free()

	const ICON_SIZE = Vector2(11.878, 11.269)
	const FULL_MANA_REGION = Rect2(Vector2(20.585, 37.491), ICON_SIZE)  # Full mana icon region
	const FULL_HEALTH_REGION = Rect2(Vector2(20.196, 11.938), ICON_SIZE)  # Full mana icon region
	const ICON_SCALE = Vector2(2, 2)
	const ICON_MARGIN = 1
	const EMPTY_MANA_REGION = Rect2(Vector2(32.585, 37.491), ICON_SIZE)  # Empty mana icon region
	const EMPTY_HEALTH_REGION = Rect2(Vector2(32.196, 11.938), ICON_SIZE)  # Full mana icon region
	
 	# Create new icons based on the updated MAX_MP
	for i in range(MAX_MP):
		var mana_icon = Sprite2D.new()
		mana_icon.texture = preload("res://Assets/Heart&ManaUi.png")  # Load the sprite sheet
		mana_icon.region_enabled = true  # Enable region usage
		mana_icon.region_rect = FULL_MANA_REGION if i < MP else EMPTY_MANA_REGION
		mana_icon.scale = ICON_SCALE
		
		# Calculate position with margin
		var x_offset = i * (ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN)
		mana_icon.position = Vector2(x_offset, 20)
		mana_container.add_child(mana_icon)
		
	for i in range(MAX_HP):
		var health_icon = Sprite2D.new()
		health_icon.texture = preload("res://Assets/Heart&ManaUi.png")  # Load the sprite sheet
		health_icon.region_enabled = true  # Enable region usage
		health_icon.region_rect = FULL_HEALTH_REGION if i < HP else EMPTY_HEALTH_REGION
		health_icon.scale = ICON_SCALE
		
		# Calculate position with margin
		var x_offset = i * (ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN)
		health_icon.position = Vector2(x_offset, 0)
		health_container.add_child(health_icon)

	
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

		if MP < MP_COST:
			print("Not enough MP")
		else:	
			is_attacking = true
			animated_sprite.play("attack")
			shoot_projectile()
			MP -= MP_COST
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
	
	
