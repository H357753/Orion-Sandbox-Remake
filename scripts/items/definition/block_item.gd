class_name BlockItemDefinition
extends ItemDefinition
## 放置时使用的block id
@export var block_id: int = 1
@export var hard:int = 10
var world: World


func primary_use(
	world: World,
	stack: ItemStack,
	position: Vector2,
	player: PlayerCharacter,
) -> void:
	self.world = world
	var pos: Vector2i = world.get_tilemap_position(position)

	var collision_shape := player.get_collision_rect()
	var shape := collision_shape.shape
	var local_rect := shape.get_rect()  # Rect2，相对于碰撞体节点
	# 转成世界坐标
	var global_rect := Rect2(
		collision_shape.global_position + local_rect.position,
		local_rect.size
	)
	var tile_origin := Vector2(pos.x * 32, pos.y * 32)
	var tile_rect := Rect2(tile_origin, Vector2(32, 32))
	# 4. 检测玩家矩形与目标格子矩形是否相交（重叠则禁止放置）
	if global_rect.intersects(tile_rect):
		return

	var tile := world.get_tile(pos)
	if not tile:
		return
	if not _can_place(pos, tile):
		return
	world.set_block(pos, stack.item.block_id)
	stack.count = stack.count - 1
	player.animation_component.start_default_swing(1)
	return


func _can_place(pos: Vector2i, tile: TileDetails) -> bool:
	var down_pos = pos - Vector2i(0, -1)
	var up_pos = pos - Vector2i(0, 1)
	var left_pos = pos - Vector2i(1, 0)
	var right_pos = pos - Vector2i(-1, 0)
	if tile.has_block():
		return false
	if tile.has_wall():
		return true
	if _has_block(down_pos) \
			or _has_block(up_pos) \
			or _has_block(left_pos) \
			or _has_block(right_pos):
		return true
	return false


func _has_block(pos: Vector2i) -> bool:
	var tile = world.get_tile(pos)
	if not tile:
		return false
	return tile.has_block()

#func place(world: World, pos: Vector2i):
#world.set_block(pos, block_id)
#
#
#func get_place_position(hit) -> Vector2i:
#return hit.block_position + hit.normal
