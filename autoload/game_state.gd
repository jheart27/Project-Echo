extends Node
## Autoloaded global game state (registered as "GameState" in project.godot).
##
## Deliberately minimal for now. This will grow to hold zone/persistence
## state, inventory, and save data as those systems come online — keep
## per-level logic out of here.

signal player_registered(player: Node3D)

var player: Node3D


func register_player(new_player: Node3D) -> void:
	player = new_player
	player_registered.emit(new_player)
