extends Node
## Autoloaded global game state (registered as "GameState" in project.godot).
##
## Progression is tracked as flags, not an inventory: picking up a keycard,
## pulling a lever, planting a charge etc. all just set a flag that doors
## and other gates check. Keep per-level logic out of here.

signal player_registered(player: Node3D)
signal flag_set(flag: StringName)

var player: Node3D

var _flags: Dictionary = {}


func register_player(new_player: Node3D) -> void:
	player = new_player
	player_registered.emit(new_player)


func set_flag(flag: StringName) -> void:
	if _flags.has(flag):
		return
	_flags[flag] = true
	flag_set.emit(flag)


func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)
