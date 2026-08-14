class_name InventoryBase
extends Resource

@export var slots: Array[ItemStack]

# ---- 核心操作 ----

func add_item(item: ItemDefinition, count: int) -> bool:
	if count <= 0: return false
	var remaining = count
	# 先尝试堆叠到已有相同物品
	for i in slots.size():
		var slot = slots[i]
		if slot and slot.item == item:
			var space = slot.item.max_stack - slot.count
			if space > 0:
				var add = min(remaining, space)
				slot.count += add
				remaining -= add
				if remaining <= 0:
					emit_changed()  # 触发 Resource 变更信号
					return true
	# 再找空位
	for i in slots.size():
		if slots[i] == null:
			slots[i] = ItemStack.new(item, remaining)
			emit_changed()
			return true
	return false  # 空间不足

func remove_item(item: ItemDefinition, count: int) -> bool:
	if count <= 0: return false
	var total = 0
	for slot in slots:
		if slot and slot.item == item:
			total += slot.count
	if total < count:
		return false
	# 从后往前扣除（便于清空尾部）
	var remaining = count
	for i in range(slots.size() - 1, -1, -1):
		var slot = slots[i]
		if slot and slot.item == item:
			var deduct = min(remaining, slot.count)
			slot.count -= deduct
			remaining -= deduct
			if slot.count <= 0:
				slots[i] = null
			if remaining <= 0:
				emit_changed()
				return true
	return false

func move_item(from: int, to: int) -> bool:
	if from == to or from < 0 or from >= slots.size() or to < 0 or to >= slots.size():
		return false
	var src = slots[from]
	var dst = slots[to]
	if src == null:
		return false
	if dst == null:
		# 空格：直接移动
		slots[to] = src
		slots[from] = null
		emit_changed()
		return true
	if src.item == dst.item:
		# 同类合并
		var space = dst.item.max_stack - dst.count
		if space <= 0:
			return false  # 目标已满
		var move_count = min(space, src.count)
		dst.count += move_count
		src.count -= move_count
		if src.count <= 0:
			slots[from] = null
		emit_changed()
		return true
	# 不同物品交换
	slots[from] = dst
	slots[to] = src
	emit_changed()
	return true

# ---- 查询 ----

func get_item(index: int) -> ItemStack:
	if index < 0 or index >= slots.size():
		return null
	return slots[index]

func has_item(item: ItemDefinition, count: int) -> bool:
	var total = 0
	for slot in slots:
		if slot and slot.item == item:
			total += slot.count
			if total >= count:
				return true
	return false

# ---- 重置功能 ----

func clear() -> void:
	for i in slots.size():
		slots[i] = null
	emit_changed()
