extends RigidBody2D

var damage: int = 1

func _ready():
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage) 
		queue_free() 
