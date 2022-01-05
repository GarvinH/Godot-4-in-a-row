extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$Create_server.hide()
	$Create_server/Server_ip.text = Network.local_ip_address
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	get_tree().change_scene("res://Scenes/Game.tscn")
	
func _player_connected(id) -> void:
	print("Player " + str(id) + " has connected")
	
func _player_disconnected(id) -> void:
	print("Player " + str(id) + " has disconnected")
	
func _connected_to_server() -> void:
	print("Connected to server")

func _on_Create_server_pressed():
	$Main_screen.hide()
	$Create_server.show()
	Network.create_server()


func _on_Join_server_pressed():
	var server_join_ip = $Main_screen/Join_ip.text
	if (server_join_ip != ""):
		$Main_screen.hide()
		Network.join_server(server_join_ip)


func _on_Exit_pressed():
	$Create_server.hide()
	$Main_screen.show()
