class_name InventoryComponent
extends Node
signal inventory_changed
@export var inventory: InventoryBase

func _ready():
	# 监听 InventoryBase 自身的变更信号，转发给组件使用者
	inventory.changed.connect(_on_inventory_data_changed)

func _on_inventory_data_changed():
	inventory_changed.emit()

# ---- 包装方法 ----

func add_item(item: ItemDefinition, amount: int = 1) -> bool:
	return inventory.add_item(item, amount)  # 内部已 emit 信号

func remove_item(item: ItemDefinition, amount: int) -> bool:
	return inventory.remove_item(item, amount)

func get_item(index: int) -> ItemStack:
	return inventory.get_item(index)

func set_item(index: int, stack: ItemStack) -> void:
	if index < 0 or index >= inventory.slots.size():
		return
	inventory.slots[index] = stack
	inventory.emit_changed()  # 会触发 changed 信号

func has_item(item: ItemDefinition, amount: int) -> bool:
	return inventory.has_item(item, amount)

func move_item(source_index: int, target: InventoryComponent, target_index: int) -> void:
	if target == self:
		# 同一个背包内的移动
		inventory.move_item(source_index, target_index)
	else:
		# 跨背包移动
		_move_between_inventories(source_index, target.inventory, target_index)
	# 因为目标 inventory 也会 emit changed，所以两个组件都会收到信号（通过各自的监听）

func _move_between_inventories(src_idx: int, dst_inv: InventoryBase, dst_idx: int) -> void:
	var src_stack = inventory.get_item(src_idx)
	if src_stack == null:
		return
	var dst_stack = dst_inv.get_item(dst_idx)

	# 目标为空
	if dst_stack == null:
		dst_inv.slots[dst_idx] = src_stack
		inventory.slots[src_idx] = null
		inventory.notify_property_list_changed()
		dst_inv.notify_property_list_changed()
		return

	# 同类合并
	if src_stack.item == dst_stack.item:
		var space = dst_stack.item.max_stack - dst_stack.count
		if space > 0:
			var amount = min(space, src_stack.count)
			dst_stack.count += amount
			src_stack.count -= amount
			if src_stack.count <= 0:
				inventory.slots[src_idx] = null
			inventory.notify_property_list_changed()
			dst_inv.notify_property_list_changed()
			return

	# 不同物品交换
	inventory.slots[src_idx] = dst_stack
	dst_inv.slots[dst_idx] = src_stack
	inventory.notify_property_list_changed()
	dst_inv.notify_property_list_changed()

# ---- 额外功能：清空 ----
func clear_inventory() -> void:
	inventory.clear()
