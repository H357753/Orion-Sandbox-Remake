extends ItemSlotBase
signal slot_clicked(_index: int)
signal slot_right_clicked(_index: int)
var _index: int

func set_slot_index(i: int) -> void:
	_index = i

func _gui_input(event):
	var global_mouse_pos = get_global_mouse_position()
	var offset = global_mouse_pos - global_position
	if event is InputEventMouseButton:
		if !event.pressed:
			return
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				slot_clicked.emit(_index,offset)
			MOUSE_BUTTON_RIGHT:
				slot_right_clicked.emit(_index,offset)
