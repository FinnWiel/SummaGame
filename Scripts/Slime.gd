extends Node2D

const SPEED = 60

var direction = 1
var hp = 3  # Health Points for the slime

@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	# Connect signals
	hitbox.connect("body_entered", self._on_body_entered)

func _process(delta: float) -> void:
	# Check RayCast2D collisions for direction change
	if raycast_right.is_colliding():
		direction = -1
		animated_sprite.flip_h = true
	elif raycast_left.is_colliding():
		direction = 1
		animated_sprite.flip_h = false
	
	# Move the node
	position.x += direction * SPEED * delta

func _on_body_entered(body: Node) -> void:
	print("Collision detected with:", body.name)

	if body.name == "SmokeAttack":  # Check if the colliding body is the bolt
		hp -= 1  # Reduce slime's HP by 1
		print("Slime HP:", hp)

		# Change modulate color to red on hit
		animated_sprite.modulate = Color(225, 0, 0)  # Red tint
		body.queue_free()
		await get_tree().create_timer(.2).timeout
		animated_sprite.modulate = Color(1, 1, 1)  # Default (white)
		# If HP reaches 0, remove the slime
		if hp <= 0:
			print("Slime is defeated!")
			queue_free()
