extends StaticBody3D
## Pump-station auxiliary generator. Priming it sets the `power_restored`
## flag that the grand hall door checks — the first "restore power to open
## the way" puzzle beat.

@export var flag: StringName = &"power_restored"

@onready var _indicator: MeshInstance3D = $Indicator
@onready var _light: OmniLight3D = $GenLight


func _ready() -> void:
	if GameState.has_flag(flag):
		_set_running()


func get_interact_prompt() -> String:
	return "[E] Generator" if GameState.has_flag(flag) else "[E] Prime generator"


func interact(player: Node) -> void:
	if GameState.has_flag(flag):
		if player and player.has_method("show_message"):
			player.show_message("Running. Barely.", 2.0)
		return
	GameState.set_flag(flag)
	_set_running()
	if player and player.has_method("show_message"):
		player.show_message("GENERATOR PRIMED — PARTIAL POWER RESTORED TO STRATUM GRID.")


func _set_running() -> void:
	var green := Color(0.3, 1.0, 0.45)
	var mat := _indicator.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.emission = green
	_light.light_color = green
	_light.light_energy = 1.6
