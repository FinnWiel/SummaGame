extends Node2D

const SPEED = 150
var direction = 1
var HP = 12

const player_character = preload("res://Scripts/PlayerCharacter.gd")
const small_slime_scene = preload("res://Scenes/Slime.tscn")  # Replace with actual path
const portal_scene = preload("res://Scenes/Portal.tscn")  # Replace with actual path

@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var ray_cast_down: RayCast2D = $RayCastDown
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", self.take_damage)

func _process(delta: float) -> void:
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
	direction *= -1
	animated_sprite.flip_h = !animated_sprite.flip_h
	ray_cast_down.position.x *= -1
	
func take_damage(amount):
	HP -= amount.damage
	animated_sprite.modulate = Color(0, 0, 1)  # Red on hit
	await get_tree().create_timer(.2).timeout
	if HP <= 0:
		die()
	animated_sprite.modulate = Color(1, 1, 1)
	print("Enemy HP:", HP)

func die():
	# Get the ground Y-position from the boss's current global position
	var ground_y = global_position.y
	
	# Spawn 4 small slimes at the same Y, but varied X positions
	for i in range(4):
		var slime_instance = small_slime_scene.instantiate()
		get_parent().add_child(slime_instance)
		var offset_x = randf_range(-130, 130)
		slime_instance.global_position = Vector2(global_position.x + offset_x, ground_y)
		slime_instance.scale *= 4  # Scale slime by 4
	
	# Spawn portal at same ground position
	var portal_instance = portal_scene.instantiate()
	get_parent().add_child(portal_instance)
	portal_instance.global_position = Vector2(global_position.x, ground_y)
	portal_instance.scale *= 4  # Scale portal by 4
	
	queue_free()
