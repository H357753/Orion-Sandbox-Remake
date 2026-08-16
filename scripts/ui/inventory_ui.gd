extends Control
## player相关引用
@onready var players_manager: PlayerManager = %PlayersManager
var player_inventory:InventoryComponent

## 快捷栏与背包栏
var _slot_nodes: Array[Node] # 存放所有格子节点（需实现 set_slot_index 和 refresh）
var _fast_slot_nodes: Array[Node]

## node节点引用
@onready var item_ammunition: HBoxContainer = $ItemAmmunition
@onready var item_slots: GridContainer = $ItemSlots
@onready var item_hotbar: HBoxContainer = $ItemHotbar
@onready var item_held_slot: ItemSlotBase = $"../ItemHeldSlot" # 手持槽节点
@onready var item_panel_slots: HBoxContainer = $"../HUD/FastPannelUI/ItemPanelSlots"

var _last_selected_item_index:int = -1

## 快捷栏高亮

func _ready():
	# 初始化手持槽
	item_held_slot.visible = false
	_collect_slots()

	# 连接所有格子的点击信号
	for slot in _slot_nodes:
		slot.slot_clicked.connect(_on_slot_clicked)

	# 连接 DragManager 信号（注意：都是无参信号）
	DragManager.drag_started.connect(_on_drag_started)
	DragManager.drag_updated.connect(_on_drag_updated)
	DragManager.drag_finished.connect(_on_drag_finished)


func _collect_slots():
	_slot_nodes.clear()
	_slot_nodes += item_hotbar.get_children()
	_slot_nodes += item_slots.get_children()
	for i in _slot_nodes.size():
		_slot_nodes[i].set_slot_index(i)

	_fast_slot_nodes += item_panel_slots.get_children()


func bind_player(player:PlayerCharacterEntity) -> void:
	player_inventory = player.inventory_component
	player_inventory.inventory_changed.connect(refresh)
	player.selected_item_changed.connect(switch_selected_item_slot)
	switch_selected_item_slot(player.selected_item_index)
	refresh()

func switch_selected_item_slot(_selected_item_index:int) -> void:
	if _selected_item_index != _last_selected_item_index:
		_fast_slot_nodes[_last_selected_item_index].set_selection_visible(false)
		_fast_slot_nodes[_selected_item_index].set_selection_visible(true)
		_last_selected_item_index = _selected_item_index

func refresh():
	if not player_inventory:
		return
	for i in _slot_nodes.size():
		_slot_nodes[i].refresh(player_inventory.get_item(i))
	for i in _fast_slot_nodes.size():
		_fast_slot_nodes[i].refresh(player_inventory.get_item(i))


# ---- 信号处理（无参，由 DragManager 状态驱动） ----
func _on_drag_started():
	# 开始拖拽时，手持槽显示物品（内容由 ItemHeldSlot 内部根据 DragManager.stack 更新）
	item_held_slot.visible = true
	# 注意：offset 已在点击时设置，此处不再重复设置
	refresh() # 刷新格子（源格子已被清空）


func _on_drag_updated():
	# 手中物品变化（如交换后）
	# ItemHeldSlot 内部会自动更新显示，无需额外操作
	refresh()


func _on_drag_finished():
	item_held_slot.visible = false
	# 清除显示（ItemHeldSlot 内部会清空）
	refresh()


# ---- 点击格子 ----
func _on_slot_clicked(index: int, offset: Vector2):
	if DragManager.is_dragging():
		# 放下或交换
		DragManager.handle_drop(player_inventory, index)
		# 后续刷新由信号触发，无需手动 refresh
	else:
		# 开始拖拽：先设置手持槽偏移，再调用 begin_drag
		item_held_slot.offset = offset # 直接设置偏移量
		DragManager.begin_drag(player_inventory, index)
		# begin_drag 会触发 drag_started，进而调用 _on_drag_started，显示手持槽并刷新


@warning_ignore("unused_parameter")
func _process(delta: float):
	if not visible:
		DragManager.cancel_drag()
	if Input.is_action_just_pressed("inventory"):
		visible = !visible


func _on_bag_button_pressed() -> void:
	visible = !visible
