extends Node
@onready var players_manager: PlayerManager = %PlayersManager
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func _on_host_pressed():
	create_server()


func _on_join_pressed():
	create_client("127.0.0.1")


func create_server():
	var err = peer.create_server(7753)
	if err != OK:
		print(err)
		return
	multiplayer.multiplayer_peer = peer
	print("Server Started")
	players_manager.initialize_server()


func create_client(ip: String):
	var err = peer.create_client(ip, 7753)
	if err != OK:
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected)


func _on_connected():
	print("连接服务器成功")
