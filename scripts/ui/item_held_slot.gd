extends ItemSlotBase

var offset: Vector2 = Vector2.ZERO

func _ready():
	# 连接拖拽信号（确保只在 _ready 连接一次）
	DragManager.drag_started.connect(_on_drag_started)
	DragManager.drag_updated.connect(_on_drag_updated)
	DragManager.drag_finished.connect(_on_drag_finished)
	visible = false

# 内部更新显示
func refresh(stack: ItemStack) -> void:
	if stack == null:
		visible = false
		return
	super(stack)

func _clear_display():
	item_icon.texture = null
	item_count.text = ""

# 信号处理
func _on_drag_started():
	visible = true
	refresh(DragManager.stack)

func _on_drag_updated():
	refresh(DragManager.stack)

func _on_drag_finished():
	visible = false
	_clear_display()

# 每帧更新位置（因为鼠标移动）
@warning_ignore("unused_parameter")
func _process(delta):
	if visible:
		global_position = get_global_mouse_position() - offset
