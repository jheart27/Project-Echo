extends MeshInstance3D
## Emissive light panel with a matching omni light — the standard visible
## light fixture for the megastructure. Tint per zone via `light_color`
## (cold fluorescent, sodium orange, terminal green...). `flicker` gives an
## unstable fluorescent stutter.

@export var light_color := Color(0.85, 0.92, 1.0)
@export var light_energy := 1.6
@export var flicker := false

var _mat: StandardMaterial3D

@onready var _light: OmniLight3D = $Light


func _ready() -> void:
	_light.light_color = light_color
	_light.light_energy = light_energy
	# Panels are everywhere — fade their omni out at range so distant
	# sectors don't pay light cost (the emissive slab still glows).
	_light.distance_fade_enabled = true
	_light.distance_fade_begin = 35.0
	_light.distance_fade_length = 12.0
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.08, 0.09, 0.1)
	_mat.emission_enabled = true
	_mat.emission = light_color
	_mat.emission_energy_multiplier = 2.2
	material_override = _mat
	if flicker:
		_run_flicker()


func _run_flicker() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(0.08, 2.4)).timeout
		if not is_inside_tree():
			return
		_light.light_energy = light_energy * randf_range(0.05, 0.4)
		_mat.emission_energy_multiplier = 0.3
		await get_tree().create_timer(randf_range(0.04, 0.18)).timeout
		if not is_inside_tree():
			return
		_light.light_energy = light_energy
		_mat.emission_energy_multiplier = 2.2
