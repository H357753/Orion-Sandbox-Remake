extends Node

signal drag_started
signal drag_finished
signal drag_updated   # 手中物品发生变化时（交换或合并后仍有剩余）

var source_inventory: InventoryComponent
var source_slot: int = -1
var stack: ItemStack = null   # 当前手中的物品（副本，实际数据已从源格移除）

# ---- 开始拖拽 ----
func begin_drag(inv: InventoryComponent, index: int):
	if is_dragging():
		return
	var item = inv.get_item(index)
	if item == null:
		return
	# 从源格子拿走物品
	inv.set_item(index, null)
	source_inventory = inv
	source_slot = index
	stack = item
	drag_started.emit()

# ---- 结束拖拽（清空状态，不自动放回） ----
func end_drag():
	if not is_dragging():
		return
	source_inventory = null
	source_slot = -1
	stack = null
	drag_finished.emit()

# ---- 取消拖拽（将物品放回源格或尝试放入背包） ----
func cancel_drag():
	if not is_dragging():
		return
	if source_inventory != null and source_slot >= 0:
		# 如果源格子仍然为空，放回
		if source_inventory.get_item(source_slot) == null:
			source_inventory.set_item(source_slot, stack)
		else:
			# 源格子已被占用（极少发生），尝试添加到背包第一个空位
			source_inventory.add_item(stack.item, stack.count)
	end_drag()

# ---- 核心交互：放下或交换 ----
func handle_drop(target_inv: InventoryComponent, target_slot: int):
	if not is_dragging():
		return

	var target_stack = target_inv.get_item(target_slot)

	# 情况1：目标为空 → 放下手中物品，结束拖拽
	if target_stack == null:
		target_inv.set_item(target_slot, stack)
		end_drag()
		return

	# 情况2：同类且可合并
	if target_stack.item == stack.item:
		var space = target_stack.item.max_stack - target_stack.count
		if space > 0:
			var amount = min(space, stack.count)
			target_stack.count += amount
			stack.count -= amount
			if stack.count <= 0:
				# 手中物品全部放入
				end_drag()
			else:
				# 手中仍有剩余，更新UI
				drag_updated.emit()
			return
		# 如果目标已满，则不能合并，执行交换（情况3）

	# 情况3：不同类（或同类已满）→ 交换
	# 将目标物品取出，手中原物品放入目标格
	var old_hand = stack
	target_inv.set_item(target_slot, old_hand)
	stack = target_stack
	# 源格子已为空，无需操作
	drag_updated.emit()   # 手中物品已改变

# ---- 辅助查询 ----
func is_dragging() -> bool:
	return stack != null
