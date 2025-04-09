extends Control
# Allow inputs even when the game is paused
@export var process_in_pause: bool = true

@onready var main = $"../../../"
@onready var resume_button: Button = $VBoxContainer/resume
@onready var quit_button: Button = $VBoxContainer/quit
@onready var volume_slider: HSlider = $VBoxContainer/VolumeSlider

@export
var bus_name: String

var bus_index: int

func _ready():
	# Hide the menu at the start
	visible = false
	# Connect button signals
	resume_button.pressed.connect(_on_resume_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	bus_index = AudioServer.get_bus_index(bus_name)

	# Ensure the slider value starts correctly (converting dB to linear scale)
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	volume_slider.value = db_to_linear(current_db)  # Maps dB (0) to 1.0

	# Connect volume slider event
	volume_slider.value_changed.connect(_on_value_changed)
# Toggle pause when Esc is pressed
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		print("Esc pressed - Toggling pause")
		toggle_pause()

# Function to pause/unpause the game
func toggle_pause():
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused
	Input.action_release("attack")

# Resume button callback
func _on_resume_pressed():
	toggle_pause()

# Quit button callback
func _on_quit_pressed():
	get_tree().quit()
	
func _on_value_changed(value: float):
	# Convert the slider's linear value to dB and apply it
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
