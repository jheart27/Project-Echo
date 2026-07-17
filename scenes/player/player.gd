extends CharacterBody3D
## First-person controller: deliberate walk, stamina-limited sprint, a
## modest jump, mouse look, subtle head bob, and an interact raycast.
## No combat yet. Thermal optics toggle on G once the goggles flag is set.

signal stamina_changed(current: float, maximum: float)
signal interact_focus_changed(interactable: Node)

@export_group("Movement")
@export var walk_speed := 3.0
@export var sprint_speed := 5.4
@export var acceleration := 9.0
@export var deceleration := 11.0
## Deliberately low — a heavy hop over debris, not an FPS bunny jump.
@export var jump_velocity := 4.0

@export_group("Stamina")
@export var max_stamina := 100.0
@export var sprint_drain_per_second := 22.0
@export var regen_per_second := 16.0
@export var regen_delay := 1.2
## After emptying the bar completely, sprint stays locked until stamina
## recovers to this value — prevents rapid tap-sprint stutter at zero.
@export var exhaustion_recovery_threshold := 25.0

@export_group("Look")
@export var mouse_sensitivity := 0.0022
@export var max_pitch_degrees := 85.0
@export var sprint_fov_boost := 5.0

@export_group("Head Bob")
@export var bob_enabled := true
@export var walk_bob_frequency := 2.1
@export var sprint_bob_frequency := 2.9
@export var bob_amplitude := 0.045

@export_group("Interaction")
@export var interact_distance := 2.5

@export_group("Health")
@export var max_health := 100.0
## Health slowly recovers after this many seconds without taking a hit —
## no medkits or health HUD; feedback is the red flash and audio later.
@export var health_regen_delay := 8.0
@export var health_regen_rate := 6.0

var stamina: float
var health: float
var _dead := false
var _hurt_timer := 0.0
var _exhausted := false
var _regen_cooldown := 0.0
var _bob_phase := 0.0
var _base_fov := 75.0
var _focused_interactable: Node = null

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _interact_ray: RayCast3D = $Head/Camera3D/InteractRay
@onready var _prompt_label: Label = $HUD/InteractPrompt
@onready var _message_label: Label = $HUD/Message
@onready var _damage_flash: ColorRect = $HUD/DamageFlash
@onready var _death_overlay: ColorRect = $HUD/DeathOverlay

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _message_tween: Tween


func _ready() -> void:
	stamina = max_stamina
	health = max_health
	_base_fov = _camera.fov
	_interact_ray.target_position = Vector3(0.0, 0.0, -interact_distance)
	_interact_ray.add_exception(self)
	_prompt_label.text = ""
	_message_label.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)


func _unhandled_input(event: InputEvent) -> void:
	if _dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		var pitch_limit := deg_to_rad(max_pitch_degrees)
		_head.rotation.x = clampf(_head.rotation.x, -pitch_limit, pitch_limit)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("toggle_thermal"):
		if GameState.has_flag(&"thermal_goggles"):
			GameState.set_thermal(not GameState.thermal_active)
			show_message("OPTICS: THERMAL" if GameState.thermal_active else "OPTICS: STANDARD", 1.2)
		else:
			show_message("NO OPTICS MODULE", 1.2)


func _physics_process(delta: float) -> void:
	if _dead:
		if not is_on_floor():
			velocity.y -= _gravity * delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	if _hurt_timer == 0.0 and health < max_health:
		health = minf(health + health_regen_rate * delta, max_health)

	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	var sprinting := _update_stamina(delta, wish_dir)
	var target_speed := sprint_speed if sprinting else walk_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	if wish_dir != Vector3.ZERO:
		horizontal = horizontal.lerp(wish_dir * target_speed, 1.0 - exp(-acceleration * delta))
	else:
		horizontal = horizontal.lerp(Vector3.ZERO, 1.0 - exp(-deceleration * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	move_and_slide()

	_update_head_bob(delta, horizontal.length(), sprinting)
	var target_fov := _base_fov + (sprint_fov_boost if sprinting else 0.0)
	_camera.fov = lerpf(_camera.fov, target_fov, 1.0 - exp(-6.0 * delta))
	_update_interact_focus()


func _update_stamina(delta: float, wish_dir: Vector3) -> bool:
	var wants_sprint := (
		Input.is_action_pressed("sprint")
		and wish_dir != Vector3.ZERO
		and is_on_floor()
	)
	var sprinting := wants_sprint and not _exhausted and stamina > 0.0

	if sprinting:
		stamina = maxf(stamina - sprint_drain_per_second * delta, 0.0)
		_regen_cooldown = regen_delay
		if stamina == 0.0:
			_exhausted = true
		stamina_changed.emit(stamina, max_stamina)
	else:
		_regen_cooldown = maxf(_regen_cooldown - delta, 0.0)
		if _regen_cooldown == 0.0 and stamina < max_stamina:
			stamina = minf(stamina + regen_per_second * delta, max_stamina)
			if _exhausted and stamina >= exhaustion_recovery_threshold:
				_exhausted = false
			stamina_changed.emit(stamina, max_stamina)

	return sprinting


func _update_head_bob(delta: float, speed: float, sprinting: bool) -> void:
	if not bob_enabled:
		return
	if is_on_floor() and speed > 0.3:
		var frequency := sprint_bob_frequency if sprinting else walk_bob_frequency
		_bob_phase += TAU * frequency * delta
		_camera.position.y = sin(_bob_phase) * bob_amplitude
		_camera.position.x = cos(_bob_phase * 0.5) * bob_amplitude * 0.6
	else:
		_bob_phase = 0.0
		_camera.position = _camera.position.lerp(Vector3.ZERO, 1.0 - exp(-8.0 * delta))


func _update_interact_focus() -> void:
	var hit: Node = null
	if _interact_ray.is_colliding():
		var collider := _interact_ray.get_collider()
		if collider is Node and collider.is_in_group("interactable"):
			hit = collider

	if hit == _focused_interactable:
		return
	_focused_interactable = hit
	interact_focus_changed.emit(hit)
	if hit == null:
		_prompt_label.text = ""
	elif hit.has_method("get_interact_prompt"):
		_prompt_label.text = hit.get_interact_prompt()
	else:
		_prompt_label.text = "[E] Interact"


func _try_interact() -> void:
	if _focused_interactable and _focused_interactable.has_method("interact"):
		_focused_interactable.interact(self)


## Displays a line of diegetic text (terminal output, pickup notices) with a
## typewriter reveal, then fades it out. Interactables call this instead of
## printing to the console.
func show_message(text: String, hold_time := 4.0) -> void:
	if _message_tween:
		_message_tween.kill()
	_message_label.text = text
	_message_label.modulate.a = 1.0
	_message_label.visible_characters = 0
	_message_tween = create_tween()
	_message_tween.tween_property(
		_message_label, "visible_characters", text.length(), maxf(0.4, text.length() * 0.025)
	)
	_message_tween.tween_interval(hold_time)
	_message_tween.tween_property(_message_label, "modulate:a", 0.0, 0.8)


func take_damage(amount: float, from_direction: Vector3 = Vector3.ZERO) -> void:
	if _dead:
		return
	health = maxf(health - amount, 0.0)
	_hurt_timer = health_regen_delay
	if from_direction != Vector3.ZERO:
		velocity += from_direction.normalized() * 6.0 + Vector3.UP * 2.5
	var flash := create_tween()
	_damage_flash.modulate.a = 0.55
	flash.tween_property(_damage_flash, "modulate:a", 0.0, 0.5)
	if health == 0.0:
		_die()


func _die() -> void:
	_dead = true
	_prompt_label.text = ""
	var fade := create_tween()
	fade.tween_property(_death_overlay, "modulate:a", 1.0, 1.1)
	fade.tween_callback(_respawn).set_delay(1.6)


func _respawn() -> void:
	# GameState is an autoload, so flags (keycard, power, goggles) survive
	# the reload; collected pickups also stay gone (see pickup.gd).
	get_tree().reload_current_scene()
