class_name BlockItemDefinition
extends ItemDefinition
## 放置时使用的block id
@export var block_id: int = 1
@export var hard: int = 10


func primary_use(player: PlayerCharacterEntity, position: Vector2, world: World) -> void:
	var pos := world.get_tilemap_position(position)
	var stack := player.inventory_component.get_item(player.selected_item_index)
	world.set_block(pos, stack.item.block_id)
	player.inventory_component.add_item_count(player.selected_item_index, -1)

#func place(world: World, pos: Vector2i):
#world.set_block(pos, block_id)
#
#
#func get_place_position(hit) -> Vector2i:
#return hit.block_position + hit.normal
