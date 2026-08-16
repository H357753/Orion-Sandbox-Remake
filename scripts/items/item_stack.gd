class_name ItemStack
extends Resource
@export var item: ItemDefinition
@export var count: int = 1:
	set(i):
		count = i
		emit_changed()

func _init(a: ItemDefinition = ResourceManager.get_item_definition(0), b: int = 1) -> void:
	item = a
	count = b

func clone():
	var stack := ItemStack.new()
	stack.item = item
	stack.count = count
	return stack
