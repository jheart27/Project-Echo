extends StaticBody3D
## Sliding security door. Interacting opens it if the player carries
## `required_flag` (see GameState flags). `sealed` doors never open —
## use them as lore/decor gates to future zones.

@export var required_flag: StringName = &"keycard_stratum9"
@export var locked_message := "LOCKED — ACCESS CARD REQUIRED"
@export var sealed := false
@export var sealed_message := "NO POWER. SEALED FROM THE OTHER SIDE."
@export var open_height := 4.6
@export var open_time := 4.0

var _open := false

@onready var _indicator: MeshInstance3D = $IndicatorFront
@onready var _door_light: OmniLight3D = $DoorLight


func get_interact_prompt() -> String:
	return "" if _open else "[E] Door panel"


func interact(player: Node) -> void:
	if _open:
		return
	if sealed:
		_show(player, sealed_message)
		_deny_flash()
		return
	if required_flag != &"" and not GameState.has_flag(required_flag):
		_show(player, locked_message)
		_deny_flash()
		return
	_open = true
	var green := Color(0.3, 1.0, 0.45)
	var mat := _indicator.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		mat.emission = green
	_door_light.light_color = green
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y + open_height, open_time)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _show(player: Node, message: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(message)


func _deny_flash() -> void:
	var tween := create_tween()
	tween.tween_property(_door_light, "light_energy", 4.0, 0.06)
	tween.tween_property(_door_light, "light_energy", 1.5, 0.3)
