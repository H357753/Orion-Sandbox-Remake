extends Button
@onready var world: World = $"../../.."

func _on_button_down() -> void:
	world.set_wall.rpc(Vector2i(17,17),1)
	world.set_wall.rpc(Vector2i(19,19),1)
