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
# Child Timer instead of an awaited coroutine: it is freed with the node
# when its sector streams out, so no resume-on-freed-instance errors.
var _gutter_timer: Timer

@onready var _eye_light: OmniLight3D = $EyeLight


func _ready() -> void:
	_gutter_timer = Timer.new()
	_gutter_timer.one_shot = true
	add_child(_gutter_timer)
	_gutter_timer.timeout.connect(_on_gutter_timeout)
	_gutter_timer.start(randf_range(0.3, 3.0))


func get_interact_prompt() -> String:
	return "[E] Examine"


func interact(player: Node) -> void:
	if player and player.has_method("show_message") and not lines.is_empty():
		player.show_message(lines[_next])
		_next = (_next + 1) % lines.size()


func _on_gutter_timeout() -> void:
	_eye_light.light_energy = randf_range(0.05, 0.5)
	_gutter_timer.start(randf_range(0.3, 3.0))
