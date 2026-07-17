extends Node
## Full-screen post stack. Grain/vignette (GrainLayer, layer 100) is always
## on. Thermal (ThermalLayer, layer 99) is toggled through GameState and
## must live on its OWN CanvasLayer below the grain layer: the grain pass's
## screen capture only reliably includes content from previously composited
## layers, not earlier items within the same layer.

@onready var _thermal_layer: CanvasLayer = $ThermalLayer


func _ready() -> void:
	_thermal_layer.visible = GameState.thermal_active
	GameState.thermal_toggled.connect(_on_thermal_toggled)


func _on_thermal_toggled(active: bool) -> void:
	_thermal_layer.visible = active
