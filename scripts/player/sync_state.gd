extends Node
@export var flip:bool
@export var motion_state:String
@export var velocity:Vector2
func _on_motion_event_received(event: StringName) -> void:
	if is_multiplayer_authority():
		motion_state = event
