class_name ItemStack
extends Resource
@export var item: ItemDefinition
@export var count: int = 1


func _init(a: ItemDefinition = ResourceManager.get_item_definition(0), b: int = 1) -> void:
	item = a
	count = b


func clone():
	var stack := ItemStack.new()
	stack.item = item
	stack.count = count
	return stack
