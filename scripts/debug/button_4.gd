extends Button
@onready var players_manager: PlayerManager = %PlayersManager

func _on_pressed() -> void:
	players_manager.get_local_player().get_inventory_component().remove_item(ResourceManager.get_item_definition(0),45)
	players_manager.get_local_player().get_inventory_component().remove_item(ResourceManager.get_item_definition(1),45)
