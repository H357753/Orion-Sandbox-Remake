@tool
extends Node
@export var ITEM_DATABASE:Array[ItemDefinition]
@export var ITEM_DURABILITY_DATABASE:Array[Texture]
@export var ITEM_FRAME_DATABASE:Array[Texture]
@export var ITEM_BACKGROUND:Texture
func get_item_definition(id:int) -> ItemDefinition:
	return ITEM_DATABASE[id]
