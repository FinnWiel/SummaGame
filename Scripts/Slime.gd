extends Node2D

const SPEED = 200
const GRAVITY = 900.0
const MAX_FALL_SPEED = 1200.0

var direction = 1
var HP = 3
var velocity: Vector2 = Vector2.ZERO

const player_character = preload("res://Scripts/PlayerCharacter.gd")

@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown 
@onready var gravity_ray: RayCast2D = $Grav 
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", self.take_damage)

func _process(delta: float) -> void:
	var collider_right = raycast_right.get_collider()
	var collider_left = raycast_left.get_collider()

	# Gravity simulation using Grav raycast
	if !gravity_ray.is_colliding():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
	else:
		velocity.y = 0

	# Apply movement
	position.x += direction * SPEED * delta
	position.y += velocity.y * delta

	# Direction change logic (uses ray_cast_down)
	if !ray_cast_down.is_colliding():
		toggle_direction()
	if raycast_right.is_colliding() and !collider_right.is_in_group("player"):
		toggle_direction()
	elif raycast_left.is_colliding() and !collider_left.is_in_group("player"):
		toggle_direction()

func toggle_direction():
	direction *= -1
	animated_sprite.flip_h = !animated_sprite.flip_h
	ray_cast_down.position.x *= -1
	raycast_left.position.x *= -1
	raycast_right.position.x *= -1

func take_damage(amount):
	if amount is RigidBody2D:
		amount.queue_free()  # Destroy the projectile that hit us

	HP -= amount.damage
	animated_sprite.modulate = Color(1, 0, 0)  # Red on hit
	await get_tree().create_timer(0.2).timeout
	if HP <= 0:
		die()
	animated_sprite.modulate = Color(1, 1, 1)
	print("Enemy HP:", HP)


func die():
	queue_free()
