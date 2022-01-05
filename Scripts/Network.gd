extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 2

var server : NetworkedMultiplayerENet = null
var client : NetworkedMultiplayerENet = null

var local_ip_address = ""

func _ready():
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") and !ip.ends_with("1"):
			local_ip_address = ip
		
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().network_peer = server

func join_server(server_ip_address) -> void:
	client = NetworkedMultiplayerENet.new()
	client.create_client(server_ip_address, DEFAULT_PORT)
	get_tree().network_peer = client

func _connected_to_server():
	print("Successfully connected to server")
	
func _server_disconnected():
	print("Disconnected from the server")
