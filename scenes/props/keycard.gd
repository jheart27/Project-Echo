extends StaticBody3D
## Keycard pickup. There is no inventory — taking it just sets a GameState
## flag that gated doors check. Slowly spins so it reads as a pickup.

@export var flag: StringName = &"keycard_stratum9"
@export var pickup_message := "ACCESS CARD ACQUIRED — DOOR CONTROL, THIS STRATUM"


func _process(delta: float) -> void:
	rotate_y(delta * 1.2)


func get_interact_prompt() -> String:
	return "[E] Take access card"


func interact(player: Node) -> void:
	GameState.set_flag(flag)
	if player and player.has_method("show_message"):
		player.show_message(pickup_message)
	queue_free()
