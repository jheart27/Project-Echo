extends StaticBody3D
## A dead Synth chassis — set dressing that watches you back. The eye light
## gutters at random so it never quite reads as fully off. Examining it
## cycles a few lines.

@export var lines: Array[String] = [
	"A Synth chassis, hand-welded. It has too many ribs.",
	"Powered down. The eye still holds a charge from somewhere.",
	"The arm is longer than it should be. Built in a hurry — or built by something that had never seen one.",
]

var _next := 0

@onready var _eye_light: OmniLight3D = $EyeLight


func _ready() -> void:
	_gutter()


func get_interact_prompt() -> String:
	return "[E] Examine"


func interact(player: Node) -> void:
	if player and player.has_method("show_message") and not lines.is_empty():
		player.show_message(lines[_next])
		_next = (_next + 1) % lines.size()


func _gutter() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(0.3, 3.0)).timeout
		if not is_inside_tree():
			return
		_eye_light.light_energy = randf_range(0.05, 0.5)
