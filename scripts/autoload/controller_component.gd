class_name ControllerManager
extends Node
enum Action {
	NONE ,
	ACTIVATED,
	ATTACK,
	BUILD,
	CONSUME,
	DESTROY_WALL,
	END_DESTROY_WALL,
	DESTROY_BLOCK,
	END_DESTROY_BLOCK,
	SHOOT,
}
const MOUSE_AREA_RADIUS := 3

@onready var _world: World = $".."
var _player: PlayerCharacterEntity

#var entity_under_cursor: bool = false
var _action:Action = Action.NONE
var mouse_on_area: bool = false

var destory_tile_pos:Vector2i

## 输入
var primary_pressed: bool = false
var secondary_pressed: bool = false

func _unhandled_input(event):
	if not _player:
		return	
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_player.selected_item_index = wrapi(_player.selected_item_index + 1, 0, 9)
					_action = Action.NONE
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_player.selected_item_index = wrapi(_player.selected_item_index - 1, 0, 9)
					_action = Action.NONE
	if event is InputEventKey and event.pressed:
		var index = event.keycode - KEY_1
		if index >= 0 and index < 9:
			_player.selected_item_index = index
			_action = Action.NONE


func _process(delta: float) -> void:
	if not _player:
		return
	mouse_on_area = _check_mouse_on_area()
	if Input.is_action_just_pressed("mouse_left_interaction") and not _is_hand_busy() and not _is_busy():
		_try_primary_action()
	if Input.is_action_pressed("mouse_left_interaction") and not _is_hand_busy():
		_process_primary_hold()
	if Input.is_action_just_released("mouse_left_interaction"):
		_action = Action.NONE
	# 选中的生物失效或死亡时清空
	#if selectedCreature != null and (not selectedCreature.active or not selectedCreature.alive):
	#selectedCreature = null


func _try_primary_action() -> void:
	var item = _get_selected_item()
	var pos:=_player.get_global_mouse_position()
	
	if item != null \
	and can_place(item,pos,_world) \
	and mouse_on_area:
		_use_item_primary(item)
		_start_default_swing()
		_action = Action.BUILD
		return
	if can_destory_block(pos,_world) and mouse_on_area:
		_use_item_primary(item)
		_start_default_swing()
		destory_tile_pos = pos
		_action = Action.DESTROY_BLOCK
		return
	_action = Action.ACTIVATED
	_start_default_swing()

func _process_primary_hold() -> void:
	var item = _get_selected_item()
	if item == null or not mouse_on_area:
		return
	var pos:=_player.get_global_mouse_position()
	match _action:
		Action.ACTIVATED:
			return
		Action.BUILD:
			if can_place(item,pos,_world):
				_use_item_primary(item)
				_start_default_swing()
			return
		Action.DESTROY_BLOCK:
			if can_destory_block(pos,_world) and is_same_block(pos,destory_tile_pos,_world) and mouse_on_area:
				_use_item_primary(item)
				_start_default_swing()
			return

func _use_item_primary(item: ItemDefinition) -> void:
	var pos = _player.get_global_mouse_position()
	item.primary_use(_player, pos, _world)

## item 属性判断
func can_place(item:ItemDefinition,position:Vector2,world:World) -> bool:
	## 检测该物品是否拥有放置方法
	if item is not BlockItemDefinition:
		return false
	
	var pos: Vector2i = world.get_tilemap_position(position)
	var tile := world.get_tile(pos)
	
	## 检测放置地点是否在阻挡玩家
	var collision_shape := _player.collision
	var shape := collision_shape.shape
	var local_rect := shape.get_rect() # Rect2，相对于碰撞体节点
	## 转成世界坐标
	var global_rect := Rect2(collision_shape.global_position + local_rect.position, local_rect.size)
	var tile_origin := Vector2(pos.x * 32, pos.y * 32)
	var tile_rect := Rect2(tile_origin, Vector2(32, 32))
	# 4. 检测玩家矩形与目标格子矩形是否相交（重叠则禁止放置）
	if global_rect.intersects(tile_rect):
		return false
	
	var down_pos = pos - Vector2i(0, -1)
	var up_pos = pos - Vector2i(0, 1)
	var left_pos = pos - Vector2i(1, 0)
	var right_pos = pos - Vector2i(-1, 0)
	if tile.has_block():
		return false
	if tile.has_wall():
		return true
	if world._has_block(down_pos) \
			or world._has_block(up_pos) \
			or world._has_block(left_pos) \
			or world._has_block(right_pos):
		return true
	if world._has_wall(down_pos) \
			or world._has_wall(up_pos) \
			or world._has_wall(left_pos) \
			or world._has_wall(right_pos):
		return true
	return false

func can_destory_block(position:Vector2,world:World) -> bool:
	##TODO: 排除大部分物品
	var pos: Vector2i = world.get_tilemap_position(position)
	var tile := world.get_tile(pos)
	if tile == null or not tile.has_block():
		return false
	return true

func is_same_block(position:Vector2,last_position:Vector2,world:World,) -> bool:
	var pos: Vector2i = world.get_tilemap_position(position)
	var last_pos: Vector2i = world.get_tilemap_position(last_position)
	return pos == last_pos



func _check_mouse_on_area() -> bool:
	if not _player:
		return false

	var mouse_world := _player.get_global_mouse_position()
	var player_tile := _world.get_tilemap_position(_player.global_position)
	var mouse_tile := _world.get_tilemap_position(mouse_world)

	return (
		mouse_tile.x >= player_tile.x - MOUSE_AREA_RADIUS
		and mouse_tile.x <= player_tile.x + MOUSE_AREA_RADIUS
		and mouse_tile.y >= player_tile.y - MOUSE_AREA_RADIUS
		and mouse_tile.y <= player_tile.y + MOUSE_AREA_RADIUS + 1
	)

func _is_hand_busy() -> bool:
	if not _player.animation_component:
		return false
	return _player.animation_component.get_is_hand_busy()

func _is_busy() -> bool:
	return _action != Action.NONE

func _get_selected_item() -> ItemDefinition:
	var stack = _player.inventory_component.get_item(_player.selected_item_index)
	if stack == null:
		return null
	return stack.item

func _start_default_swing() -> void:
	var direction := _player.sync_flip
	_player.animation_component.start_default_swing(direction)
