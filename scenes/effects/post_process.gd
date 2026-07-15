extends CanvasLayer
## Full-screen post stack. The grain/vignette Overlay is always on; the
## ThermalOverlay is toggled through GameState (requires the goggles flag —
## see player.gd input handling). ThermalOverlay draws first, so film grain
## and vignette still apply on top of the thermal image.

@onready var _thermal: ColorRect = $ThermalOverlay


func _ready() -> void:
	_thermal.visible = GameState.thermal_active
	GameState.thermal_toggled.connect(_on_thermal_toggled)


func _on_thermal_toggled(active: bool) -> void:
	_thermal.visible = active
