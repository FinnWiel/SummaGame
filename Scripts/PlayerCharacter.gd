extends CharacterBody2D

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

var being_attacked = false
var jump_particles_played = false
var is_attacking = false
var invincibility_time: float = 1.0
var time_accumulated: float = 0.0

func _ready():
	update_upgrade_icons()
	# Sync runtime variables with singleton
	if PlayerData.HP > PlayerData.MAX_HP:
		PlayerData.HP = PlayerData.MAX_HP
	if PlayerData.MP > PlayerData.MAX_MP:
		PlayerData.MP = PlayerData.MAX_MP

func _process(delta: float) -> void:
	time_accumulated += delta
	update_ui()
	if time_accumulated >= 1.0:
		time_accumulated -= 1.0
		if PlayerData.MP < PlayerData.MAX_MP:
			PlayerData.MP += PlayerData.MPS

func update_ui() -> void:
	var mana_container = game_ui.get_node("StatsContainer/Mana")
	var health_container = game_ui.get_node("StatsContainer/Health")
	for child in mana_container.get_children():
		mana_container.remove_child(child)
		child.queue_free()
	for child in health_container.get_children():
		health_container.remove_child(child)
		child.queue_free()

	const ICON_SIZE = Vector2(11.878, 11.269)
	const ICON_SCALE = Vector2(2, 2)
	const ICON_MARGIN = 1
	const FULL_MANA_REGION = Rect2(Vector2(20.585, 37.491), ICON_SIZE)
	const EMPTY_MANA_REGION = Rect2(Vector2(32.585, 37.491), ICON_SIZE)
	const FULL_HEALTH_REGION = Rect2(Vector2(20.196, 11.938), ICON_SIZE)
	const EMPTY_HEALTH_REGION = Rect2(Vector2(32.196, 11.938), ICON_SIZE)

	for i in range(PlayerData.MAX_MP):
		var mana_icon = Sprite2D.new()
		mana_icon.texture = preload("res://Assets/Heart&ManaUi.png")
		mana_icon.region_enabled = true
		mana_icon.region_rect = FULL_MANA_REGION if i < PlayerData.MP else EMPTY_MANA_REGION
		mana_icon.scale = ICON_SCALE
		mana_icon.position = Vector2(i * (ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN), 20)
		mana_container.add_child(mana_icon)

	for i in range(PlayerData.MAX_HP):
		var health_icon = Sprite2D.new()
		health_icon.texture = preload("res://Assets/Heart&ManaUi.png")
		health_icon.region_enabled = true
		health_icon.region_rect = FULL_HEALTH_REGION if i < PlayerData.HP else EMPTY_HEALTH_REGION
		health_icon.scale = ICON_SCALE
		health_icon.position = Vector2(i * (ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN), 0)
		health_container.add_child(health_icon)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			PlayerData.extra_jumps = 1 if not PlayerData.hasJumpUpgrade else 2
			jump_particles_played = false
		elif PlayerData.extra_jumps > 0:
			velocity.y = DOUBLE_JUMP_VELOCITY
			PlayerData.extra_jumps -= 1

	if not is_on_floor() and not jump_particles_played:
		var instance = jump_particles.instantiate()
		instance.global_position = $Marker2D.global_position
		get_parent().add_child(instance)
		instance.play("jump_particles")
		jump_particles_played = true

	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack("attack", PlayerData.MP_COST)
	if Input.is_action_just_pressed("attack2") and not is_attacking:
		attack("attack2", PlayerData.MP_COST_2)

	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	if not is_attacking:
		if is_on_floor():
			animated_sprite.play("run" if direction != 0 else "idle")
		else:
			animated_sprite.play("jump" if velocity.y < 0 else "fall")

	if direction:
		velocity.x = direction * PlayerData.SPEED
	else:
		var deceleration = DECELERATION_GROUND if is_on_floor() else DECELERATION_AIR
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

	move_and_slide()

	var OFFSET = 50
	attack_point.global_position = global_position + Vector2(-OFFSET if animated_sprite.flip_h else OFFSET, 0)

func attack(type, cost) -> void:
	if PlayerData.MP < cost:
		print("Not enough MP")
	else:
		is_attacking = true
		animated_sprite.play("attack")
		shoot_projectile(type)
		PlayerData.MP -= cost
		await animated_sprite.animation_finished
		is_attacking = false

func shoot_projectile(attack) -> void:
	var projectile = smoke_attack.instantiate()
	projectile.global_position = $AttackPoint.global_position
	var dir = -1 if animated_sprite.flip_h else 1
	projectile.linear_velocity = Vector2(dir * 1000, 0)
	projectile.damage = PlayerData.damage
	var sprite = projectile.get_node("Smoke")
	if attack == "attack2":
		sprite.scale = Vector2(7, 7)
		sprite.modulate = Color(1, 0, 10)
	sprite.flip_h = dir < 0
	get_parent().add_child(projectile)

func _on_hitbox_area_entered(area) -> void:
	if area.is_in_group("enemies") and not being_attacked:
		being_attacked = true
		take_damage(1)
		if PlayerData.HP <= 0:
			die();
		player_sprite.modulate = Color(1.2, 1.2, 1.2)
		await get_tree().create_timer(invincibility_time).timeout
		player_sprite.modulate = Color(1, 1, 1)
		being_attacked = false

func take_damage(amount):
	PlayerData.HP -= amount
	if PlayerData.HP <= 0:
		die()

func die():
	print("Player died!")
	PlayerData.reset()
	get_tree().change_scene_to_file("res://GUI/Menus/DeathMenu.tscn")

func apply_upgrade(upgrade_type: String, amount: int):
	match upgrade_type:
		"mana":
			PlayerData.MAX_MP += amount
			PlayerData.MP += amount
			PlayerData.hasManaUpgrade = true
		"life":
			PlayerData.MAX_HP += amount
			PlayerData.HP += amount
			PlayerData.hasLifeUpgrade = true
		"attack":
			PlayerData.damage += 1
			PlayerData.hasAttackUpgrade = true
		"speed":
			PlayerData.SPEED += 100
			PlayerData.hasSpeedUpgrade = true
		"jump":
			PlayerData.hasJumpUpgrade = true
			PlayerData.extra_jumps += 1
	update_upgrade_icons()

func update_upgrade_icons():
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

	var x_offset = 0
	var upgrades = [
		{ "enabled": PlayerData.hasLifeUpgrade, "region": HEALTH_REGION },
		{ "enabled": PlayerData.hasManaUpgrade, "region": MANA_REGION },
		{ "enabled": PlayerData.hasSpeedUpgrade, "region": SPEED_REGION },
		{ "enabled": PlayerData.hasJumpUpgrade, "region": JUMP_REGION },
		{ "enabled": PlayerData.hasAttackUpgrade, "region": ATTACK_REGION }
	]

	for upgrade in upgrades:
		if upgrade["enabled"]:
			var icon = Sprite2D.new()
			icon.texture = preload("res://Assets/spritesheet_16x16.png")
			icon.region_enabled = true
			icon.region_rect = upgrade["region"]
			icon.scale = ICON_SCALE
			icon.position = Vector2(x_offset, 0)
			active_container.add_child(icon)
			x_offset += UPGRADE_ICON_SIZE.x * ICON_SCALE.x - ICON_MARGIN
