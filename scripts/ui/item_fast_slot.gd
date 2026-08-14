extends ItemSlotBase
@onready var item_selection: TextureRect = $ItemSelection

func set_selection_visible(i: bool) -> void:
	item_selection.visible = i
