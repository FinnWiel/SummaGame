extends Node2D

@export var upgrade_type: String = "mana" # Mana or Life
@export var upgrade_amount: int = 1
@onready var hitbox: Area2D = $Hitbox

func _ready() -> void:
	hitbox.connect("body_entered", _on_area_entered)
	
func _on_area_entered(body: Node) -> void:
	if body.has_method("apply_upgrade"):
		body.apply_upgrade(upgrade_type, upgrade_amount)
		queue_free() 
