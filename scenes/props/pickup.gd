extends StaticBody3D
## Generic flag pickup (keycard, goggles, ...). There is no inventory —
## taking it just sets a GameState flag that gates and abilities check.
## Slowly spins so it reads as a pickup.

@export var flag: StringName = &""
@export var prompt := "[E] Take item"
@export var pickup_message := ""
@export var spin_speed := 1.2


func _process(delta: float) -> void:
	rotate_y(delta * spin_speed)


func get_interact_prompt() -> String:
	return prompt


func interact(player: Node) -> void:
	if flag != &"":
		GameState.set_flag(flag)
	if pickup_message != "" and player and player.has_method("show_message"):
		player.show_message(pickup_message)
	queue_free()
