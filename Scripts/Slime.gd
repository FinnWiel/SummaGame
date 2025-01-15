extends Node2D

const SPEED = 60

var direction = 1
@onready var raycast_right: RayCast2D = $RaycastRight
@onready var raycast_left: RayCast2D = $RaycastLeft
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	# Connect signals
	hitbox.connect("body_entered", self._on_body_entered)
	hitbox.connect("body_exited", self._on_body_exited)

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
	if body == RigidBody2D:
		body.queue_free()

func _on_body_exited(body: Node) -> void:
	print("Collision ended with:", body.name)
