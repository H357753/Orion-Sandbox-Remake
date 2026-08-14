# addons/item_importer/item_importer_plugin.gd
@tool
extends EditorPlugin

const ICON_DIR = "res://atlas/items_icon.sprites/"
const TEXTURE_DIR = "res://atlas/items_texture.sprites/"
const OUTPUT_DIR = "res://resource/items/"
const DATABASE_PATH = "res://resource/item_database.tres"   # 直接保存到该路径

var panel: Control
var item_list: ItemList
var current_item: ItemDefinition
var current_path: String = ""

# UI 控件引用（无 id_spin）
var name_edit: LineEdit
var desc_edit: TextEdit
var max_stack_spin: SpinBox
var type_option: OptionButton
var destroyable_check: CheckBox

# 预览控件
var icon_preview: TextureRect
var texture_preview: TextureRect

func _enter_tree():
	panel = _create_panel()
	add_control_to_bottom_panel(panel, "Item Importer")
	refresh_list()

func _exit_tree():
	remove_control_from_bottom_panel(panel)
	panel.queue_free()

func _create_panel() -> Control:
	var main = HSplitContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# 左侧：资源列表 + 按钮
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(250, 0)

	var btn_refresh = Button.new()
	btn_refresh.text = "刷新列表"
	btn_refresh.pressed.connect(refresh_list)
	left_panel.add_child(btn_refresh)

	var btn_import = Button.new()
	btn_import.text = "从图标/纹理导入"
	btn_import.pressed.connect(_on_import_pressed)
	left_panel.add_child(btn_import)

	var btn_export_db = Button.new()
	btn_export_db.text = "导出数据库 (ItemDatabase)"
	btn_export_db.pressed.connect(_on_export_database_pressed)
	left_panel.add_child(btn_export_db)

	item_list = ItemList.new()
	item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_list.item_selected.connect(_on_item_selected)
	left_panel.add_child(item_list)

	# 右侧：属性编辑器
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_child(scroll)

	var form = VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(form)

	# ---- 名称 ----
	form.add_child(_make_label("名称"))
	name_edit = LineEdit.new()
	form.add_child(name_edit)

	# ---- 描述 ----
	form.add_child(_make_label("描述"))
	desc_edit = TextEdit.new()
	desc_edit.custom_minimum_size = Vector2(0, 80)
	form.add_child(desc_edit)

	# ---- 最大堆叠 ----
	form.add_child(_make_label("最大堆叠"))
	max_stack_spin = SpinBox.new()
	max_stack_spin.min_value = 1
	max_stack_spin.max_value = 999
	max_stack_spin.step = 1
	form.add_child(max_stack_spin)

	# ---- 类型 ----
	form.add_child(_make_label("类型"))
	type_option = OptionButton.new()
	type_option.add_item("material")
	type_option.add_item("weapon")
	type_option.add_item("armor")
	type_option.add_item("consumable")
	type_option.add_item("tool")
	form.add_child(type_option)

	# ---- 可破坏性 ----
	destroyable_check = CheckBox.new()
	destroyable_check.text = "可破坏"
	form.add_child(destroyable_check)

	# ---- 图标预览 ----
	form.add_child(_make_label("图标"))
	icon_preview = TextureRect.new()
	icon_preview.custom_minimum_size = Vector2(64, 64)
	icon_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	form.add_child(icon_preview)

	# ---- 纹理预览 ----
	form.add_child(_make_label("纹理"))
	texture_preview = TextureRect.new()
	texture_preview.custom_minimum_size = Vector2(64, 64)
	texture_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	texture_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_preview.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	form.add_child(texture_preview)

	# ---- 保存按钮 ----
	var btn_save = Button.new()
	btn_save.text = "保存修改"
	btn_save.pressed.connect(_on_save_pressed)
	form.add_child(btn_save)

	main.add_child(left_panel)
	main.add_child(right_panel)
	return main

func _make_label(text: String) -> Label:
	var label = Label.new()
	label.text = text
	return label

# ------------------------------------------------
# 刷新资源列表（自然排序）
# ------------------------------------------------
func refresh_list():
	item_list.clear()
	if not DirAccess.dir_exists_absolute(OUTPUT_DIR):
		return

	var dir = DirAccess.open(OUTPUT_DIR)
	if dir == null:
		return

	var ids: Array = []
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			ids.append(file.get_basename())
		file = dir.get_next()
	dir.list_dir_end()

	ids.sort_custom(func(a: String, b: String) -> bool:
		return a.naturalnocasecmp_to(b) < 0
	)

	for id in ids:
		item_list.add_item(id)

# ------------------------------------------------
# 列表选择事件
# ------------------------------------------------
func _on_item_selected(index: int):
	var id = item_list.get_item_text(index)
	current_path = OUTPUT_DIR + id + ".tres"
	current_item = load(current_path) as ItemDefinition
	if current_item:
		_fill_editor(current_item)
	else:
		push_warning("无法加载资源: " + current_path)

# ------------------------------------------------
# 填充编辑器控件（无 id）
# ------------------------------------------------
func _fill_editor(item: ItemDefinition):
	if name_edit == null or desc_edit == null or max_stack_spin == null \
			or type_option == null or destroyable_check == null \
			or icon_preview == null or texture_preview == null:
		push_warning("编辑器控件未完全初始化")
		return

	name_edit.text = item.name
	desc_edit.text = item.description
	max_stack_spin.value = item.max_stack
	destroyable_check.button_pressed = item.destroyable

	icon_preview.texture = item.icon
	texture_preview.texture = item.texture

	#for i in range(type_option.item_count):
		#if type_option.get_item_text(i) == item.type:
			#type_option.select(i)
			#break

# ------------------------------------------------
# 保存当前修改（无 id）
# ------------------------------------------------
func _on_save_pressed():
	if current_item == null or current_path == "":
		push_warning("没有选中的资源")
		return

	if name_edit == null or desc_edit == null or max_stack_spin == null \
			or type_option == null or destroyable_check == null:
		push_warning("编辑器控件未完全初始化")
		return

	current_item.name = name_edit.text
	current_item.description = desc_edit.text
	current_item.max_stack = int(max_stack_spin.value)
	current_item.destroyable = destroyable_check.button_pressed
	#current_item.type = type_option.get_item_text(type_option.selected)

	var err = ResourceSaver.save(current_item, current_path)
	if err == OK:
		print("已保存: ", current_path)
		refresh_list()
	else:
		push_error("保存失败: ", err)

# ------------------------------------------------
# 导入：从 0 开始顺序编号
# ------------------------------------------------
func _on_import_pressed():
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var dir = DirAccess.open(ICON_DIR)
	if dir == null:
		push_error("图标文件夹不存在: " + ICON_DIR)
		return

	# 收集所有有效的数字文件名
	var valid_ids: Array[int] = []
	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var basename = file.get_basename()
			if basename.is_valid_int():
				valid_ids.append(int(basename))
			else:
				push_warning("跳过无效文件（文件名非数字）: " + file)
		file = dir.get_next()
	dir.list_dir_end()

	valid_ids.sort()

	var index = 0
	for old_id in valid_ids:
		var id_str = str(old_id)
		var icon = load(ICON_DIR + id_str + ".tres")
		var texture = load(TEXTURE_DIR + "item_" + id_str + ".tres")
		if texture == null:
			push_warning("缺少纹理: item_" + id_str + "，跳过")
			continue

		var item = ItemDefinition.new()
		# 无 id 字段
		item.name = ""          # 留空，可后续编辑
		item.icon = icon
		item.texture = texture

		var out_path = OUTPUT_DIR + str(index) + ".tres"
		var err = ResourceSaver.save(item, out_path)
		if err == OK:
			print("已生成: ", out_path)
		else:
			push_error("生成失败: ", out_path)
		index += 1

	refresh_list()

# ------------------------------------------------
# 导出数据库：使用 ItemDatabase 资源
# ------------------------------------------------
func _on_export_database_pressed():
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	
	var items: Array[ItemDefinition] = []
	var dir = DirAccess.open(OUTPUT_DIR)
	if dir == null:
		push_error("无法打开目录: " + OUTPUT_DIR)
		return

	dir.list_dir_begin()
	var file = dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.ends_with(".tres"):
			var path = OUTPUT_DIR + file
			var item = load(path) as ItemDefinition
			if item:
				items.append(item)
			else:
				push_warning("无法加载物品: " + path)
		file = dir.get_next()
	dir.list_dir_end()

	if items.is_empty():
		push_warning("没有找到任何物品，数据库未生成")
		return

	# 创建 ItemDatabase 实例（需要项目中有 class_name ItemDatabase 的定义）
	var db = ItemDefinition.new()
	db.ITEM = items

	var err = ResourceSaver.save(db, DATABASE_PATH)
	if err == OK:
		print("数据库已导出至: ", DATABASE_PATH)
		get_editor_interface().get_resource_filesystem().scan()
	else:
		push_error("保存数据库失败: ", err)
