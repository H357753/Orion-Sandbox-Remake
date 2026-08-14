class_name ItemSlotBase
extends Control
@onready var item_background: TextureRect = $ItemBackground
@onready var item_durability: TextureRect = $ItemDurability
@onready var item_icon: TextureRect = $ItemIcon
@onready var item_frame: TextureRect = $ItemFrame
@onready var item_count: Label = $ItemCount
@warning_ignore("unused_private_class_variable")
var _durabilityHidden:bool = false

func refresh(stack: ItemStack) -> void:
	if not stack:
		_clean()
		return
	item_background.texture = ResourceManager.ITEM_BACKGROUND
	item_frame.texture = ResourceManager.ITEM_FRAME_DATABASE[0]
	var item = stack.item
	item_icon.texture = item.icon
	item_count.text = str(stack.count) if stack.count >= 1 else ""

func _clean() -> void:
	item_icon.texture = null
	item_count.text = ""
	item_background.texture = null
	item_frame.texture = null
