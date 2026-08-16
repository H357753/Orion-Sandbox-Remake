# World.gd (片段)
#extends Node2D
#@export var width: int = 600
#@export var height: int = 500
#
#var tiles: Array = []  # 一维数组模拟二维, 索引 = x + y * width
#var tile_entities: Dictionary = {}  # 坐标 Vector2i -> TileEntity 节点
#
#enum TileLayer{
#DEFAULT = 1,
#}
#
#func _ready():
#init_tiles()
#
#func init_tiles():
#tiles.resize(width * height)
#for x in range(width):
#for y in range(height):
#var tile = Tile.new()
#tiles[x + y * width] = tile
## 可选: 设置默认墙或地基
## tile.set_wall_id(Wall.WOOD.id)
#
## World.gd
#@onready var tile_map: TileMapLayer = $TileMap
#func sync_tile_to_tilemap(x: int, y: int):
#var tile = get_tile(x, y)
#var atlas_coords: Vector2i
#
## 根据 Block ID 和 Block Data 计算 Atlas 坐标
#if tile.get_block_id() > 0:
#atlas_coords = Vector2i(tile.get_block_data() >> 6, 0) # 举例
class_name World
extends Node2D
const CHUNK_SIZE := 32
var world_width: int
var world_height: int
@export var tiles: Array[TileDetails]
@onready var tilemap_manager: TileMapManager = $TileMapManager

func _ready() -> void:
	_create_world(200, 200)
	for i in range(200):
		set_block.rpc(Vector2i(i, 22), 1)

func _create_world(width: int, height: int):
	world_width = width
	world_height = height
	tiles.resize(width * height)
	for i in tiles.size():
		tiles[i] = TileDetails.new()
	tilemap_manager.load_world()

func get_tilemap_position(position: Vector2) -> Vector2i:
	position = position.floor()
	var local_pos := to_local(position)
	var pos := Vector2i(floor(local_pos.x / 32), floor(local_pos.y / 32))
	return pos


func get_tile(pos: Vector2i) -> TileDetails:
	if pos.x >= world_width:
		return null
	if pos.x < 0:
		return null
	if pos.y >= world_height:
		return null
	if pos.y < 0:
		return null
	return tiles[pos.x + pos.y * world_width]


@rpc("any_peer", "call_local")
func set_block(pos: Vector2i, id: int, atlas_id: Vector2i = Vector2i(0, 0)):
	var tile = get_tile(pos)
	tile.block_id = id
	tile.block_atlas_id = atlas_id
	tilemap_manager.mark_dirty(pos)


@rpc("any_peer", "call_local")
func set_wall(pos: Vector2i, id: int, atlas_id: Vector2i = Vector2i(0, 0)):
	var tile = get_tile(pos)
	tile.wall_id = id
	tile.wall_atlas_id = atlas_id
	tilemap_manager.mark_dirty(pos)


func send_world_to_player(peer_id: int) -> void:
	var data := []
	for tile in tiles:
		data.append(
			{
				"block_id": tile.block_id,
				"block_atlas_id": tile.block_atlas_id,
				"wall_id": tile.wall_id,
				"wall_atlas_id": tile.wall_atlas_id,
			}
		)
	receive_world.rpc_id(peer_id, world_width, world_height, data)


@rpc("authority", "call_remote")
func receive_world(width: int, height: int, data: Array) -> void:
	world_width = width
	world_height = height
	tiles.resize(width * height)
	for i in data.size():
		var tile := TileDetails.new()
		tile.block_id = data[i]["block_id"]
		tile.block_atlas_id = data[i]["block_atlas_id"]
		tile.wall_id = data[i]["wall_id"]
		tile.wall_atlas_id = data[i]["wall_atlas_id"]
		tiles[i] = tile
	tilemap_manager.load_world()


func _has_block(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	if not tile:
		return false
	return tile.has_block()

func _has_wall(pos: Vector2i) -> bool:
	var tile = get_tile(pos)
	if not tile:
		return false
	return tile.has_wall()


# World.gd 补充
#var light_nodes: Dictionary = {}  # key: Vector2i, value: Light2D
#
#func update_tile_light(x: int, y: int):
#var tile = get_tile(x, y)
#var pos = Vector2i(x, y)
#
#if tile.get_block_id() == Block.TORCH.id:  # 假设火把id
#if not light_nodes.has(pos):
#var light = Light2D.new()
#light.texture = preload("res://light.png")
#light.position = Vector2(x * 32 + 16, y * 32 + 16)
#add_child(light)
#light_nodes[pos] = light
#tile.light_effect_node_path = light.get_path()  # 存储路径便于查找
#else:
#if light_nodes.has(pos):
#var light = light_nodes[pos]
#light.queue_free()
#light_nodes.erase(pos)
#tile.light_effect_node_path = NodePath()
