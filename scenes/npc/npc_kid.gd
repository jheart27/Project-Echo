extends CharacterBody3D
## Lost kid — the first NPC and escort beat. Found hiding; interact to
## have her follow (interact again to make her wait), lead her near the
## vent point and she runs to it and escapes somewhere too small for you.
## One hit from anything kills her, permanently for this run.
##
## Visuals are a placeholder box-figure; swapping to a billboard Sprite3D
## (Doom-style) or a modeled character later only touches the meshes.

signal died
signal escaped

enum State { HIDING, FOLLOW, WAIT, ESCAPING, DEAD }

@export var vent_point: NodePath
@export var follow_speed := 4.6
@export var walk_speed := 2.4
@export var follow_distance := 1.6
@export var vent_trigger_distance := 3.0
@export var rescue_flag: StringName = &"kid_rescued"
@export var death_flag: StringName = &"kid_dead"
## The streaming sector this NPC lives in — locked while she follows so
## the loader can never delete her mid-escort.
@export var home_sector: StringName = &"deep"

var _state := State.HIDING
var _holds_sector_lock := false
var _vent: Node3D
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _glow: OmniLight3D = $Glow


func _ready() -> void:
	# Outcomes are permanent for the run: a rescued (or killed) kid must
	# not reappear when the sector streams back in or the scene reloads.
	if GameState.has_flag(rescue_flag) or GameState.has_flag(death_flag):
		queue_free()
		return
	_vent = get_node_or_null(vent_point) as Node3D


func _exit_tree() -> void:
	_set_sector_lock(false)


func _set_sector_lock(want: bool) -> void:
	if want == _holds_sector_lock:
		return
	_holds_sector_lock = want
	if want:
		GameState.lock_sector(home_sector)
	else:
		GameState.unlock_sector(home_sector)


func get_interact_prompt() -> String:
	match _state:
		State.HIDING:
			return "[E] Reach out"
		State.FOLLOW:
			return "[E] Wait here"
		State.WAIT:
			return "[E] Come on"
	return ""


func interact(player: Node) -> void:
	match _state:
		State.HIDING:
			_state = State.FOLLOW
			_set_sector_lock(true)
			_say(player, "\"You hum like the lifts do. Okay. The far grate — I can slip out there. Don't let the tall ones see me.\"")
		State.FOLLOW:
			_state = State.WAIT
			_say(player, "\"I'll be small right here.\"")
		State.WAIT:
			_state = State.FOLLOW
			_say(player, "\"Right behind you.\"")


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	match _state:
		State.FOLLOW:
			_do_follow(delta)
		State.ESCAPING:
			_do_escape(delta)
		_:
			_steer(Vector3.ZERO, delta, walk_speed)
	move_and_slide()
	if _state == State.FOLLOW:
		_check_vent()


func _do_follow(delta: float) -> void:
	var player := GameState.player
	if player == null or not is_instance_valid(player):
		return
	var to_player := _flat(player.global_position - global_position)
	if to_player.length() > follow_distance:
		_face(to_player, delta)
		var speed := follow_speed if to_player.length() > 4.0 else walk_speed
		_steer(to_player.normalized(), delta, speed)
	else:
		_steer(Vector3.ZERO, delta, walk_speed)


func _check_vent() -> void:
	if _vent and global_position.distance_to(_vent.global_position) < vent_trigger_distance:
		_state = State.ESCAPING


func _do_escape(delta: float) -> void:
	if _vent == null:
		return
	var to_vent := _flat(_vent.global_position - global_position)
	if to_vent.length() > 0.4:
		_face(to_vent, delta)
		_steer(to_vent.normalized(), delta, walk_speed)
	else:
		_escape_now()


func _escape_now() -> void:
	_state = State.DEAD
	_set_sector_lock(false)
	GameState.set_flag(rescue_flag)
	_say(GameState.player, "She pries the grate and folds into the dark, somewhere too small for you. \"Thank you. Don't rust.\"")
	escaped.emit()
	queue_free()


func take_damage(_amount: float, from_direction: Vector3 = Vector3.ZERO) -> void:
	if _state == State.DEAD:
		return
	_state = State.DEAD
	_set_sector_lock(false)
	GameState.set_flag(death_flag)
	_glow.light_energy = 0.0
	remove_from_group("interactable")
	remove_from_group("fragile")
	var fall := create_tween()
	var side := 1.0 if from_direction.x >= 0.0 else -1.0
	fall.tween_property(self, "rotation:z", side * PI / 2.0, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_say(GameState.player, "The hum she followed has stopped.")
	died.emit()


func _say(player: Node, text: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(text, 5.0)


func _steer(direction: Vector3, delta: float, speed: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.lerp(direction * speed, 1.0 - exp(-12.0 * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face(direction: Vector3, delta: float, snap := 7.0) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_yaw := atan2(-direction.x, -direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-snap * delta))


func _flat(v: Vector3) -> Vector3:
	return Vector3(v.x, 0.0, v.z)
