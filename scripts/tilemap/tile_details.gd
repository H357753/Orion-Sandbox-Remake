class_name TileDetails
extends Resource

# 常量 - 对应原 Tile.SIZE
const SIZE := 32
const HALF_SIZE := 16

@export var block_id: int = 0
@export var block_atlas_id: Vector2i = Vector2i(0, 0)
@export var wall_id: int = 0
@export var wall_atlas_id: Vector2i = Vector2i(0, 0)
@export var liquid_id: int = 0
@export var liquid_atlas_id: Vector2i = Vector2i(0, 0)


func has_block() -> bool:
	return block_id > 0


func has_wall() -> bool:
	return wall_id > 0

# 核心数据打包 (32位整数)
#@export var data: int = 0:
#set(value):
#data = value
#emit_changed()
## 附加数据打包 (液态计时器)
#@export var additional_data: int = 0:
#set(value):
#additional_data = value
#emit_changed()
#
## -------- 位运算 Getter / Setter (完全复刻原逻辑) --------
## Block ID: bits 0-8 (9 bits)
#func get_block_id() -> int:
#return data & 0x01FF
#func set_block_id(id: int) -> void:
#data = (data & ~0x01FF) | (id & 0x01FF)
#
## Block Data: bits 9-16 (8 bits)
#func get_block_data() -> int:
#return (data >> 9) & 0xFF
#func set_block_data(bd: int) -> void:
#data = (data & ~(0xFF << 9)) | ((bd & 0xFF) << 9)
#
## Wall ID: bits 17-24 (8 bits)
#func get_wall_id() -> int:
#return (data >> 17) & 0xFF
#func set_wall_id(id: int) -> void:
#data = (data & ~(0xFF << 17)) | ((id & 0xFF) << 17)
#
## Wall Texture Index: bits 25-26 (2 bits)
#func get_wall_texture_index() -> int:
#return (data >> 25) & 0x03
#func set_wall_texture_index(idx: int) -> void:
#data = (data & ~(0x03 << 25)) | ((idx & 0x03) << 25)
#
## Liquid ID: bits 27-28 (2 bits)
#func get_liquid_id() -> int:
#return (data >> 27) & 0x03
#func set_liquid_id(id: int) -> void:
#data = (data & ~(0x03 << 27)) | ((id & 0x03) << 27)
#
## Liquid State: bits 0-3 of additional_data
#func get_liquid_state() -> int:
#return additional_data & 0x0F
#func set_liquid_state(state: int) -> void:
#additional_data = (additional_data & ~0x0F) | (state & 0x0F)
#
## Liquid Time Counter: bits 4-7 of additional_data
#func get_liquid_time_counter() -> int:
#return (additional_data >> 4) & 0x0F
#func set_liquid_time_counter(counter: int) -> void:
#additional_data = (additional_data & ~(0x0F << 4)) | ((counter & 0x0F) << 4)

# -------- 光照引用 (关键差异点) --------
# 注意：Resource 不能直接持有 Node 强引用，否则会阻止节点释放。
# 因此我们存储 NodePath 或唯一 ID，由 World 统一管理。
#@export var light_effect_node_path: NodePath = NodePath()
#
## 便捷方法：获取光照节点 (由 World 调用)
#func get_light_effect_node(world: Node) -> Light2D:
#if light_effect_node_path.is_empty():
#return null
#return world.get_node(light_effect_node_path) as Light2D
