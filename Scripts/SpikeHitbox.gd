extends Area2D

var damage: int = 1
	
func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(damage) 
