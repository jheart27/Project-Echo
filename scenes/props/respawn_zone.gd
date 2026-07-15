extends Area3D
## Catch volume for long drops ("don't fall" sequences): snaps the player
## back to `respawn_point` instead of killing them — there is no health
## system yet, and the fall itself is the failure state.

@export var respawn_point: NodePath
@export var message := ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body != GameState.player:
		return
	var point := get_node_or_null(respawn_point) as Node3D
	if point == null:
		return
	body.velocity = Vector3.ZERO
	body.global_position = point.global_position
	if message != "" and body.has_method("show_message"):
		body.show_message(message)
