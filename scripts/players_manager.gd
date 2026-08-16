class_name PlayerManager
extends Node
@onready var world: World = $".."
@onready var spawner: MultiplayerSpawner = $"../MultiplayerSpawner"
@onready var controller_manager: ControllerManager = %ControllerManager
@onready var inventory_ui: TextureRect = %InventoryUI

const PLAYER_CHARACTER_ENTITY = preload("uid://spua40dxacjg")

var local_player:PlayerCharacterEntity

func _ready():
	spawner.spawn_function = _spawn_player

func _spawn_player(data: Dictionary) -> Node:
	var player: PlayerCharacterEntity = PLAYER_CHARACTER_ENTITY.instantiate()
	var id: int = data["id"]
	player.name = str(id)
	player.global_position = data["position"]
	player.set_multiplayer_authority(id)
	if id == multiplayer.get_unique_id():
		local_player = player
		call_deferred("_bind_local_player", player)
	return player

func _bind_local_player(player: PlayerCharacterEntity):
	if not is_instance_valid(player) or not is_instance_valid(inventory_ui):
		return
	inventory_ui.bind_player(player)
	controller_manager._player = local_player

func initialize_server():
	if !multiplayer.is_server():
		return
	if !multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if !multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	# Host
	create_player(multiplayer.get_unique_id())
	# 已连接玩家
	for id in multiplayer.get_peers():
		create_player(id)


func create_player(peer_id: int) -> PlayerCharacterEntity:
	if !multiplayer.is_server():
		return
	var data = { "id": peer_id, "position": get_spawn_position(peer_id) }
	return spawner.spawn(data)


func _on_peer_connected(id: int):
	if not multiplayer.is_server():
		return
	print("玩家加入:", id)
	world.send_world_to_player(id)
	create_player(id)

func _on_peer_disconnected(id: int):
	print("玩家离开:", id)
	var player = self.get_node_or_null(str(id))
	if player:
		player.queue_free()


func get_spawn_position(id: int) -> Vector2:
	return Vector2(790, 492)
