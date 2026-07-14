extends StaticBody3D
## Grey-box test interactable: a wall terminal. Interacting prints the next
## log line to the Output panel and flickers the screen glow so there is
## visible in-game feedback. Stands in for real lore terminals later.

@export var log_lines: Array[String] = [
	"…connection to Authority lost 4,102 cycles ago.",
	"Maintenance route 7C sealed. Cause: unlogged.",
	"If anyone reads this: the lifts below stratum 9 are not safe.",
]

var _next_line := 0

@onready var _glow_light: OmniLight3D = $GlowLight


func get_interact_prompt() -> String:
	return "[E] Read terminal"


func interact(_player: Node) -> void:
	if not log_lines.is_empty():
		print("[Terminal] ", log_lines[_next_line])
		_next_line = (_next_line + 1) % log_lines.size()
	_flicker()


func _flicker() -> void:
	var tween := create_tween()
	tween.tween_property(_glow_light, "light_energy", 3.0, 0.05)
	tween.tween_property(_glow_light, "light_energy", 0.5, 0.08)
	tween.tween_property(_glow_light, "light_energy", 1.2, 0.2)
