extends Node2D

const SPEED = 150

var direction = 1
var HP = 12

const player_character = preload("res://Scripts/PlayerCharacter.gd")
@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D


@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", self.take_damage)

func _process(delta: float) -> void:
	# Check RayCast2D collisions for direction change
	var collider_right = raycast_right.get_collider()
	var collider_left = raycast_left.get_collider()
	
	if !ray_cast_down.is_colliding():
		toggle_direction()
	if raycast_right.is_colliding() and !collider_right.is_in_group("player"):
		toggle_direction()
	elif raycast_left.is_colliding() and !collider_left.is_in_group("player"):
		toggle_direction()
	position.x += direction * SPEED * delta

func toggle_direction():
	if direction == 1:
		direction = -1
		animated_sprite.flip_h = true
		ray_cast_down.position.x *= -1
	else:
		direction = 1
		animated_sprite.flip_h = false
		ray_cast_down.position.x *= -1
	
func take_damage(amount):
	HP -= amount.damage
	animated_sprite.modulate = Color(225, 0, 0)  # Red on hit
	await get_tree().create_timer(.2).timeout
	if HP <= 0:
		die()
	animated_sprite.modulate = Color(1, 1, 1)
	print("Enemy HP:", HP)


func die():
	queue_free()
