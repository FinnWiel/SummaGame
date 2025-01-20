extends Node2D

const SPEED = 60

var direction = 1
var HP = 3 

@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", self._on_body_entered)

func _process(delta: float) -> void:
	# Check RayCast2D collisions for direction change
	if raycast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	elif raycast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	position.x += direction * SPEED * delta

func _on_body_entered(body: Node) -> void:

	if body.name == "SmokeAttack":  # Check if the colliding body is the bolt
		HP -= 1 
		animated_sprite.modulate = Color(225, 0, 0)  # Red on hit
		body.queue_free()
		await get_tree().create_timer(.2).timeout
		animated_sprite.modulate = Color(1, 1, 1)
		if HP <= 0:
			print("Slime is defeated!")
			queue_free()
