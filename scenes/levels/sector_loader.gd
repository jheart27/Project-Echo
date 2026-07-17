extends Node3D
## Streams the level in sectors around the player so only nearby geometry
## and lights exist. The bands overlap by ~50m, so both sectors are loaded
## while you cross the boundary (bridge/platform/grand hall act as the
## airlock) and the far one is dropped only once fog and walls hide the
## seam. The start sector loads synchronously in _ready so there is a
## floor under the player on frame one (also after death reloads).

const SECTORS := {
	&"start": "res://scenes/levels/sectors/sector_start.tscn",
	&"deep": "res://scenes/levels/sectors/sector_deep.tscn",
}

var _loaded: Dictionary = {}
var _pending: Dictionary = {}
var _poll_accum := 0.0


func _ready() -> void:
	_add_sector(&"start", load(SECTORS[&"start"]))


func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum < 0.3:
		return
	_poll_accum = 0.0

	var player := GameState.player
	if player == null or not is_instance_valid(player):
		return
	var wanted := _wanted(player.global_position)
	for sector_name in SECTORS:
		if sector_name in wanted:
			_ensure(sector_name)
		elif _loaded.has(sector_name):
			_drop(sector_name)
	for sector_name in _pending.keys():
		_poll(sector_name)


## Overlapping membership bands (hysteresis comes from the overlap):
## - start: everything up to the far end of the grand hall, plus the whole
##   lower maintenance level (y < -4.5) and anything near it.
## - deep: from the chasm platform onward, plus the titan wing (x > 40).
func _wanted(p: Vector3) -> Array:
	var result: Array = []
	if p.z > -240.0 or p.y < -4.5 or (p.x < 45.0 and p.z > -260.0):
		result.append(&"start")
	# Deep loads from the bridge onward so the grand hall door (which lives
	# in the deep sector) is standing long before the player can see it.
	if (p.z < -140.0 and p.y > -4.5) or p.x > 40.0:
		result.append(&"deep")
	return result


func _ensure(sector_name: StringName) -> void:
	if _loaded.has(sector_name) or _pending.has(sector_name):
		return
	ResourceLoader.load_threaded_request(SECTORS[sector_name])
	_pending[sector_name] = true


func _poll(sector_name: StringName) -> void:
	var path: String = SECTORS[sector_name]
	var status := ResourceLoader.load_threaded_get_status(path)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		_pending.erase(sector_name)
		_add_sector(sector_name, ResourceLoader.load_threaded_get(path))
	elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		_pending.erase(sector_name)
		push_warning("Sector failed to load: %s" % path)


func _add_sector(sector_name: StringName, scene: PackedScene) -> void:
	var node := scene.instantiate()
	add_child(node)
	_loaded[sector_name] = node


func _drop(sector_name: StringName) -> void:
	var node: Node = _loaded[sector_name]
	_loaded.erase(sector_name)
	node.queue_free()
