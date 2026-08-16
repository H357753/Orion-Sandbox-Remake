class_name CharacterEntity
extends CreatureEntity
signal selected_item_changed(selected_item_index:int)
@onready var inventory_component: InventoryComponent = $InventoryComponent
@export var selected_item_index:int = 0:
	set(i):
		selected_item_index = i
		selected_item_changed.emit(i)
