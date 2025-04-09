extends CharacterBody2D

var SPEED = 500.0
const JUMP_VELOCITY = -500.0
const DOUBLE_JUMP_VELOCITY = -450.0
const DECELERATION_GROUND = 9000.0 
const DECELERATION_AIR = 800.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var jump_particles = preload("res://Scenes/JumpParticles.tscn")
@onready var smoke_attack = preload("res://Scenes/SmokeAttack.tscn")
@onready var attack_point: Marker2D = $AttackPoint
@onready var game_ui: Node2D = $"../UI/GameUI"
@onready var player_sprite: AnimatedSprite2D = $AnimatedSprite2D

@onready var gust_sound: AudioStreamPlayer2D = $GustSound
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var damage_sound: AudioStreamPlayer2D = $DamageSound
@onready var background_sound: AudioStreamPlayer2D = $BackgroundSound
@onready var boss_sound: AudioStreamPlayer2D = $BossSound

# Upgrade Trackers
var hasManaUpgrade: bool = false
var hasLifeUpgrade: bool = false
var hasAttackUpgrade: bool = false
var hasSpeedUpgrade: bool = false
var hasJumpUpgrade: bool = false

var being_attacked = false
var active_upgrades = 0
var jump_particles_played = false
var extra_jumps = 1 # Double jumps
var is_attacking = false

# Hitpoints
var MAX_HP = 3
var HP = MAX_HP 
var HPS = 1


# Magicpoints
var MAX_MP: float = 3
var MP: float = MAX_MP
var MPS: float = 1
var MP_COST: float = 1
var MP_COST_2: float = 2

# Attack damage
var damage: int = 1

var invincibility_time: float = 0.75

var time_accumulated: float = 0.0

func _ready() -> void:
	background_sound.play()

func _process(delta: float) -> void:
	time_accumulated += delta
	update_ui()
	if time_accumulated >= 1.0:
		time_accumulated -= 1.0
		if MP < MAX_MP:
			MP += MPS
		
func update_ui() -> void:
	var mana_container = game_ui.get_node("StatsContainer/Mana")
	var health_container = game_ui.get_node("StatsContainer/Health")
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
			jump_sound.play()
			velocity.y = JUMP_VELOCITY
			extra_jumps = 1  # Reset jumps when touching the ground
			if hasJumpUpgrade:
				extra_jumps = 2  # Allow an extra jump if upgrade is applied
			jump_particles_played = false
		elif extra_jumps > 0:
			velocity.y = DOUBLE_JUMP_VELOCITY
			extra_jumps -= 1  # Use up a double jump	
			
	# Jump particles
	if not is_on_floor() and not jump_particles_played:
		var instance = jump_particles.instantiate()
		instance.global_position = $Marker2D.global_position
		get_parent().add_child(instance)
		
		instance.play("jump_particles")
		jump_particles_played = true
		
	# Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack("attack", 1)
			
	if Input.is_action_just_pressed("attack2") and not is_attacking:
		attack("attack2", 2)

	
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
		
func attack(type, cost) -> void:
	if MP < cost:
		print("Not enough MP")
	else:	
		is_attacking = true
		animated_sprite.play("attack")
		shoot_projectile(type)
		MP -= cost
		await animated_sprite.animation_finished
		is_attacking = false
	
	
func shoot_projectile(attack) -> void:
	gust_sound.play()
	var POJECTILE_SPEED = 1000
	var projectile = smoke_attack.instantiate()
	projectile.global_position = $AttackPoint.global_position  # Shoot from marker
	var direction = -1 if animated_sprite.flip_h else 1
	projectile.linear_velocity = Vector2(direction * POJECTILE_SPEED, 0)

	# Set projectile damage
	if attack == "attack2":
		projectile.damage = damage  # Stronger attack
		var sprite = projectile.get_node("Smoke")
		sprite.scale = Vector2(7, 7)
		sprite.modulate = Color(1, 0, 10)
	else:
		projectile.damage = damage  # Normal attack
	projectile.get_node("Smoke").flip_h = direction < 0
	get_parent().add_child(projectile)

func _on_hitbox_area_entered(area) -> void:
	if area.is_in_group("enemies") and !being_attacked:  # Ensure enemies are in this group
		being_attacked = true
		take_damage(1)  # Adjust damage as needed
		if HP <= 0:
			return
		else:
			player_sprite.modulate = Color(0.545098, 0, 0, 1.2)
			SPEED = 175.0
			await get_tree().create_timer(invincibility_time).timeout
			SPEED = 500.0
			player_sprite.modulate = Color(1,1,1,1)
			being_attacked = false

func take_damage(amount):
	damage_sound.play()
	HP -= amount
	if HP <= 0:
		die()

func die():
	print("Player died!")
	get_tree().change_scene_to_file("res://GUI/Menus/DeathMenu.tscn")
	
# Function to handle upgrades
func apply_upgrade(upgrade_type: String, amount: int):
	match upgrade_type:
		"mana":
			MAX_MP += amount
			MP += amount
			hasManaUpgrade = true
			update_upgrade_icons()
		"life":
			MAX_HP += amount
			HP += amount
			hasLifeUpgrade = true
			update_upgrade_icons()
		"attack":
			damage += 1
			hasAttackUpgrade = true
			update_upgrade_icons()
		"speed":
			SPEED += 100
			hasSpeedUpgrade = true
			update_upgrade_icons()
		"jump":
			hasJumpUpgrade = true
			extra_jumps += 1
			update_upgrade_icons()


func update_upgrade_icons():
	# Clear previous icons to prevent duplication
	const UPGRADE_ICON_SIZE = Vector2(16, 16)
	const ICON_SCALE = Vector2(2, 2)
	const ICON_MARGIN = 1
	const HEALTH_REGION = Rect2(Vector2(80, 240), UPGRADE_ICON_SIZE)
	const MANA_REGION = Rect2(Vector2(96, 240), UPGRADE_ICON_SIZE)
	const JUMP_REGION = Rect2(Vector2(240, 192), UPGRADE_ICON_SIZE)
	const SPEED_REGION = Rect2(Vector2(240, 48), UPGRADE_ICON_SIZE)
	const ATTACK_REGION = Rect2(Vector2(0, 176), UPGRADE_ICON_SIZE)
	
	var active_container = game_ui.get_node("ActiveContainer/ActiveUpgrades")
	
	for child in active_container.get_children():
		child.queue_free()

	# Generate new icons
	var x_offset = 0
	var upgrade_list = [
		{ "enabled": hasLifeUpgrade, "region": HEALTH_REGION, "offset_var": "HEALTH_OFFSET" },
		{ "enabled": hasManaUpgrade, "region": MANA_REGION, "offset_var": "MANA_OFFSET" },
		{ "enabled": hasSpeedUpgrade, "region": SPEED_REGION, "offset_var": "SPEED_OFFSET" },
		{ "enabled": hasJumpUpgrade, "region": JUMP_REGION, "offset_var": "JUMP_OFFSET" },
		{ "enabled": hasAttackUpgrade, "region": ATTACK_REGION, "offset_var": "ATTACK_OFFSET" }
	]

	for upgrade in upgrade_list:
		if upgrade["enabled"]:
			var upgrade_icon = Sprite2D.new()
			upgrade_icon.texture = preload("res://Assets/spritesheet_16x16.png")
			upgrade_icon.region_enabled = true
			upgrade_icon.region_rect = upgrade["region"]
			upgrade_icon.scale = ICON_SCALE
			upgrade_icon.position = Vector2(x_offset, 0)

			# Update the corresponding offset variable
			set(upgrade["offset_var"], x_offset)
			
			# Add to the UI container
			active_container.add_child(upgrade_icon)

			# Move the offset for the next icon
			x_offset += UPGRADE_ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN
