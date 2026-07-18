extends Node
## Autoloaded global game state (registered as "GameState" in project.godot).
##
## Progression is tracked as flags, not an inventory: picking up a keycard,
## pulling a lever, planting a charge etc. all just set a flag that doors
## and other gates check. Keep per-level logic out of here.

signal player_registered(player: Node3D)
signal flag_set(flag: StringName)
signal thermal_toggled(active: bool)

var player: Node3D
var thermal_active := false

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


func set_thermal(active: bool) -> void:
	if thermal_active == active:
		return
	thermal_active = active
	thermal_toggled.emit(active)


# --- Sector streaming locks -------------------------------------------------
# Actors whose lifetime must not be cut short by streaming (an escorting
# NPC, a scripted sequence) hold a lock on their sector; the loader keeps
# locked sectors resident regardless of player position.

var _sector_locks: Dictionary = {}


func lock_sector(sector_name: StringName) -> void:
	_sector_locks[sector_name] = _sector_locks.get(sector_name, 0) + 1


func unlock_sector(sector_name: StringName) -> void:
	var count: int = _sector_locks.get(sector_name, 0)
	if count <= 1:
		_sector_locks.erase(sector_name)
	else:
		_sector_locks[sector_name] = count - 1


func is_sector_locked(sector_name: StringName) -> bool:
	return _sector_locks.has(sector_name)
