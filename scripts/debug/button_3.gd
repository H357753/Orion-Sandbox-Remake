extends Button
@onready var players_manager: PlayerManager = %PlayersManager

func _on_pressed() -> void:
	var item = ItemStack.new(ResourceManager.get_item_definition(0),10)
	players_manager.local_player.inventory_component.set_item(0,item)
	players_manager.local_player.inventory_component.set_item(1,item.clone())
