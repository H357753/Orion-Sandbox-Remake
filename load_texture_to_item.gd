@tool
extends EditorScript
const ITEM_DATABASE = preload("uid://pjcaoo5xh4j1")
const ICON_DIR = "res://atlas/items_icon.sprites/"
const TEXTURE_DIR = "res://atlas/item_texure/"
var item_database:Array[ItemDefinition] = ITEM_DATABASE.ITEM_DATABASE

func _run() -> void:
	var icon_textures: Array[AtlasTexture] = []
	var icon_files = _get_files_in_dir(ICON_DIR, "tres")
	for i in icon_files:
		var path = ICON_DIR + i
		var tex = load(path)
		if tex is Texture:
			icon_textures.append(tex)
		else:
			push_warning("文件不是 Texture：", path)

	var textures: Array[AtlasTexture] = []
	var tex_files = _get_files_in_dir(TEXTURE_DIR, "tres")
	for i in tex_files:
		var path = TEXTURE_DIR + i
		var tex = load(path)
		textures.append(tex)
		#if tex is Texture:
			#textures.append(tex)
		#else:
			#push_warning("文件不是 Texture：", path)
	
	print(textures.size())
	print(icon_textures.size())
	var item_database: Array[ItemDefinition] = ITEM_DATABASE.item_list
	for i in item_database.size():
		item_database[i].texture = textures[i]
		item_database[i].icon = icon_textures[i]
	ITEM_DATABASE.notify_property_list_changed()


func _get_files_in_dir(dir_path: String, extension: String) -> PackedStringArray:
	var dir = DirAccess.open(dir_path)
	if not dir:
		printerr("无法打开目录：", dir_path)
		return PackedStringArray()
	
	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.get_extension() == extension:
			files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()

	# ---- 按数字从小到大排序 ----
	files.sort_custom(_compare_by_number)
	return PackedStringArray(files)

# 自定义比较函数：提取文件名中的第一个数字序列，并按数字大小比较
func _compare_by_number(a: String, b: String) -> bool:
	var num_a = _extract_first_number(a)
	var num_b = _extract_first_number(b)
	# 如果两者都提取到数字，按数字排序；否则按字典序（保证稳定性）
	if num_a != -1 and num_b != -1:
		return num_a < num_b
	elif num_a == -1 and num_b == -1:
		return a < b
	else:
		# 没有数字的排在后面（也可以根据需要调整）
		return num_a != -1  # 有数字的排前面

# 提取文件名中第一个连续的数字序列，转为整数；若无数字则返回 -1
func _extract_first_number(filename: String) -> int:
	var regex = RegEx.new()
	regex.compile("\\d+")  # 匹配一个或多个数字
	var result = regex.search(filename)
	if result:
		return result.get_string().to_int()
	return -1
