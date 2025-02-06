extends Node

@onready var scene_container: Node2D = $"."

var scenes = [
	"res://Scenes/SpeedUpgrade.tscn",
	"res://Scenes/ManaUpgrade.tscn",
	"res://Scenes/LifeUpgrade.tscn",
	"res://Scenes/DoubleJumpUpgrade.tscn",
	"res://Scenes/AttackUpgrade.tscn"
]

func _ready():
	randomize()  # Ensures different results each run
	load_random_scene()

func load_random_scene():
	if scenes.is_empty():
		print("No more power-ups left to load.")
		return
	
	# Clear previous scene if one exists
	for child in scene_container.get_children():
		child.queue_free()
	
	# Pick a random scene and remove it from the list
	var random_index = randi() % scenes.size()
	var random_scene_path = scenes.pop_at(random_index)
	
	var next_scene = load(random_scene_path).instantiate()
	
	# Add the new scene as a child of SceneContainer
	scene_container.add_child(next_scene)
