extends StaticBody3D
## Wall terminal interactable. Interacting shows the next log line as
## in-game diegetic text (via the player's show_message) and flickers the
## screen glow. Stands in for real lore terminals later.

@export var log_lines: Array[String] = [
	"…connection to Authority lost 4,102 cycles ago.",
	"Maintenance route 7C sealed. Cause: unlogged.",
	"If anyone reads this: the lifts below stratum 9 are not safe.",
]

var _next_line := 0

@onready var _glow_light: OmniLight3D = $GlowLight


func get_interact_prompt() -> String:
	return "[E] Read terminal"


func interact(player: Node) -> void:
	if not log_lines.is_empty():
		var line: String = log_lines[_next_line]
		_next_line = (_next_line + 1) % log_lines.size()
		if player and player.has_method("show_message"):
			player.show_message(line)
	_flicker()


func _flicker() -> void:
	var tween := create_tween()
	tween.tween_property(_glow_light, "light_energy", 3.0, 0.05)
	tween.tween_property(_glow_light, "light_energy", 0.5, 0.08)
	tween.tween_property(_glow_light, "light_energy", 1.2, 0.2)
