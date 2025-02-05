extends Node2D

const SPEED = 200

var direction = 1
var HP = 3 

@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", self.take_damage)

func _process(delta: float) -> void:
	# Check RayCast2D collisions for direction change
	if raycast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	elif raycast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta
	
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
