extends CharacterBody3D
## Stalker Synth — the base hostile machine. Patrols between waypoints with
## a sweeping searchlight eye; on seeing the player it chases (slightly
## faster than sprint — break line of sight to escape, don't try to outrun
## it), loses you after a few seconds unseen, searches, then returns to
## patrol. Steering is straight-line (no navmesh yet), so it belongs in
## open rooms: halls, the assembly floor.

enum State { PATROL, CHASE, SEARCH }

@export var waypoints: PackedVector3Array = PackedVector3Array()
@export var patrol_speed := 2.0
@export var chase_speed := 5.8
@export var acceleration := 14.0
@export var detection_range := 24.0
@export var detection_fov_degrees := 65.0
@export var lose_sight_time := 5.0
@export var search_time := 6.0
@export var attack_range := 1.7
## One hit is death — for you and for anything in the "fragile" group.
@export var attack_damage := 100.0
@export var attack_cooldown := 1.3

var _state := State.PATROL
var _wp_index := 0
var _last_seen := Vector3.ZERO
var _lose_timer := 0.0
var _search_timer := 0.0
var _attack_timer := 0.0
var _pause_timer := 0.0
var _sweep_phase := 0.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _eye: SpotLight3D = $EyeLight

const EYE_COLOR_CALM := Color(0.7, 0.9, 1.0)
const EYE_COLOR_HUNT := Color(1.0, 0.15, 0.1)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	_attack_timer = maxf(_attack_timer - delta, 0.0)

	var sees_player := _can_see_player()
	if sees_player:
		_last_seen = GameState.player.global_position
		_lose_timer = lose_sight_time
		if _state != State.CHASE:
			_state = State.CHASE
			_eye.light_color = EYE_COLOR_HUNT
			_eye.light_energy = 6.0

	match _state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta, sees_player)
		State.SEARCH:
			_do_search(delta)

	move_and_slide()


func _do_patrol(delta: float) -> void:
	if waypoints.is_empty():
		_steer(Vector3.ZERO, delta, patrol_speed)
		return
	if _pause_timer > 0.0:
		_pause_timer -= delta
		_steer(Vector3.ZERO, delta, patrol_speed)
		# Sweep the eye while paused; occasionally twitch — reads as wrong.
		_sweep_phase += delta * 1.1
		rotation.y += sin(_sweep_phase) * delta * 0.8
		if randf() < delta * 0.4:
			rotation.y += randf_range(-0.5, 0.5)
		return
	var target := waypoints[_wp_index]
	var to_target := _flat(target - global_position)
	if to_target.length() < 1.0:
		_wp_index = (_wp_index + 1) % waypoints.size()
		_pause_timer = randf_range(1.5, 3.5)
		return
	_face(to_target, delta)
	_steer(to_target.normalized(), delta, patrol_speed)


func _do_chase(delta: float, sees_player: bool) -> void:
	if not sees_player:
		_lose_timer -= delta
		if _lose_timer <= 0.0:
			_state = State.SEARCH
			_search_timer = search_time
			_eye.light_color = EYE_COLOR_CALM
			_eye.light_energy = 4.0
			return
	var to_target := _flat(_last_seen - global_position)
	_face(to_target, delta, 8.0)
	if to_target.length() > 0.6:
		_steer(to_target.normalized(), delta, chase_speed)
	else:
		_steer(Vector3.ZERO, delta, chase_speed)
	_try_attack()


func _do_search(delta: float) -> void:
	_search_timer -= delta
	_steer(Vector3.ZERO, delta, patrol_speed)
	_sweep_phase += delta * 1.6
	rotation.y += sin(_sweep_phase) * delta * 1.5
	if randf() < delta * 0.7:
		rotation.y += randf_range(-0.9, 0.9)
	if _search_timer <= 0.0:
		_state = State.PATROL
		_pause_timer = 1.0


func _try_attack() -> void:
	if _attack_timer > 0.0:
		return
	var targets: Array = []
	if GameState.player and is_instance_valid(GameState.player):
		targets.append(GameState.player)
	targets.append_array(get_tree().get_nodes_in_group("fragile"))
	for target in targets:
		if target is Node3D and global_position.distance_to(target.global_position) <= attack_range:
			_attack_timer = attack_cooldown
			if target.has_method("take_damage"):
				var dir := _flat(target.global_position - global_position).normalized()
				target.take_damage(attack_damage, dir)
			return


func _can_see_player() -> bool:
	var player := GameState.player
	if player == null or not is_instance_valid(player):
		return false
	var eye_pos := global_position + Vector3.UP * 2.3
	var target := player.global_position + Vector3.UP * 1.2
	var to_player := target - eye_pos
	if to_player.length() > detection_range:
		return false
	var forward := -global_transform.basis.z
	if forward.angle_to(to_player) > deg_to_rad(detection_fov_degrees) * 0.5:
		return false
	var query := PhysicsRayQueryParameters3D.create(eye_pos, target)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == player


func _steer(direction: Vector3, delta: float, speed: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.lerp(direction * speed, 1.0 - exp(-acceleration * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(direction: Vector3, delta: float, snap := 5.0) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-snap * delta))


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
