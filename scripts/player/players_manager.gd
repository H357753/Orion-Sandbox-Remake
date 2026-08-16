class_name PlayerManager
extends Node
@onready var world: World = $".."
@onready var spawner: MultiplayerSpawner = $"../MultiplayerSpawner"
const PLAYER = preload("uid://cvp25ed7xclgf")

signal local_player_set(player:PlayerCharacter)
var _local_player: PlayerCharacter


func get_local_player() ->PlayerCharacter:
	return _local_player

func set_local_player(player:PlayerCharacter):
	_local_player = player
	local_player_set.emit(player)

func get_world() -> World:
	return world

func _ready():
	spawner.spawn_function = _spawn_player

func _spawn_player(data: Dictionary) -> Node:
	var player: PlayerCharacter = PLAYER.instantiate()
	var id: int = data["id"]
	player.name = str(id)
	player.global_position = data["position"]
	player.set_multiplayer_authority(id)
	return player

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


func create_player(peer_id: int):
	if !multiplayer.is_server():
		return
	var data = { "id": peer_id, "position": get_spawn_position(peer_id) }
	spawner.spawn(data)


func _on_peer_connected(id: int):
	print("玩家加入:", id)
	create_player(id)


func _on_peer_disconnected(id: int):
	print("玩家离开:", id)
	var player = self.get_node_or_null(str(id))
	if player:
		player.queue_free()


func get_spawn_position(id: int) -> Vector2:
	return Vector2(790 + id * 32, 492)
