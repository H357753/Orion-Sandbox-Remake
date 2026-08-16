class_name TileMapManager
extends Node
@onready var world: World = $".."
@onready var block_layer: TileMapLayer = $BlockLayer
@onready var wall_layer: TileMapLayer = $WallLayer
@onready var liquid_layer: TileMapLayer = $LiquidLayer

func load_world():
	for y in world.world_height:
		for x in world.world_width:
			update_tile(Vector2i(x, y))

func update_tile(pos: Vector2i):
	var tile := world.get_tile(pos)
	#_update_wall(tile, pos)
	_update_block(tile, pos)
	#update_liquid(tile, pos)

var dirty_tiles: Array[Vector2i] = []
func mark_dirty(pos: Vector2i) -> void:
	if not dirty_tiles.has(pos):
		dirty_tiles.append(pos)

func _process(delta: float) -> void:
	for pos in dirty_tiles:
		update_tile(pos)
	dirty_tiles.clear()

func _update_block(tile: TileDetails, pos: Vector2i):
	var id = tile.block_id
	var atlas = tile.block_atlas_id
	if id == 0:
		block_layer.erase_cell(pos)
		return
	block_layer.set_cell(pos, id, atlas)

func _update_wall(tile: TileDetails, pos):
	var id = tile.wall_id
	var atlas = tile.wall_atlas_id
	if id == -1:
		wall_layer.erase_cell(pos)
		return
	wall_layer.set_cell(pos, id, atlas)


#func update_liquid(tile: TileData, pos):
	#if tile.liquid_type == LiquidType.NONE:
		#liquid_layer.erase_cell(pos)
		#return
	#liquid_layer.set_cell(pos, tile.liquid_source, tile.get_liquid_atlas())
