extends Area2D

@export var scene_prefix: String = "res://Game/Rooms/Area1/Room"  # Base path

func _on_body_entered(body):

	if body.is_in_group("player"):  
		var current_scene = get_tree().current_scene.scene_file_path  # Get current scene path
		var scene_number = _extract_scene_number(current_scene)

		if scene_number != null:
			var next_scene = scene_prefix + str(scene_number + 1) + ".tscn"
			print("Current:", current_scene)
			print("Next:", next_scene)
			if ResourceLoader.exists(next_scene):  # Ensure the scene exists
				get_tree().change_scene_to_file(next_scene)
			else:
				get_tree().change_scene_to_file("res://GUI/Menus/VictoryMenu.tscn")
		else:
			print("Could not determine next scene from:", current_scene)

func _extract_scene_number(scene_path: String):
	var filename = scene_path.get_file()
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(filename)
	if result:
		return int(result.get_string())
	return null
