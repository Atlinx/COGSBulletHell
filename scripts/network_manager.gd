class_name NetworkManager
extends Node


const SERVER_ID = 1

enum GameState {
	IDLE,
	LOBBY,
	IN_GAME
}

## Emitted when the player is connected to the server
## or the player has started hosting a server
signal connected_to_server
## Emitted when the player is disconnected or is
## quitting back to the main menu
signal game_reseted
## Emitted when the game is started
signal game_started(network_players: Array[NetworkPlayer])
## Emitted when the network players dictionary is updated
signal network_players_updated()

static var instance: NetworkManager

@export var address: String = "localhost"
@export var port: int = 9955
@export var ping_interval: float = 1
@export var ping_sample_count: int = 10

var peer: ENetMultiplayerPeer
var game_state: GameState = GameState.IDLE

var is_headless: bool = false
var is_player: bool :
	get:
		return not is_headless
var can_ready_up: bool :
	get:
		return _all_unique_usernames()
## Round trip time (Two-way delay between client and server) in msecs
var average_rtt: float
## One-way delay between client and server in msecs
var average_latency: float :
	get:
		return average_rtt / 2.0
## Time of the server in msecs
var server_time: float :
	get:
		return Time.get_ticks_msec() + server_client_time_offset
## Time of the client in msecs
var client_time: float :
	get:
		return Time.get_ticks_msec()
## Offset between server and client time in msecs
## client_time + server_client_time_offset = server_time
var server_client_time_offset: float


var _ping_timer: float
var _ping_samples: PackedFloat32Array
var _readied_player_count: int :
	get:
		var count = 0
		for player: NetworkPlayer in network_players.values():
			if player.readied_up:
				count += 1
		return count


class NetworkPlayer extends RefCounted:
	var multiplayer_id: int
	var username: String
	var readied_up: bool
	
	func to_dict() -> Dictionary:
		return {
			"multiplayer_id": multiplayer_id,
			"username": username,
			"readied_up": readied_up
		}
	
	static func from_dict(dict: Dictionary) -> NetworkPlayer:
		var lobby_player = NetworkPlayer.new()
		lobby_player.multiplayer_id = dict.get("multiplayer_id")
		lobby_player.username = dict.get("username")
		lobby_player.readied_up = dict.get("readied_up")
		return lobby_player


# [multiplayer_id: int]: NetworkPlayer
var network_players: Dictionary
var network_players_list: Array[NetworkPlayer]:
	get:
		var arr: Array[NetworkPlayer] = []
		arr.assign(network_players.values())
		return arr
var my_network_player: NetworkPlayer:
	get:
		return network_players[multiplayer.get_unique_id()]


func _enter_tree():
	if instance:
		queue_free()
		return
	instance = self
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	is_headless = "--server" in OS.get_cmdline_args()
	if is_headless:
		host_server(port)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if instance == self:
			instance = null


func _ready():
	reset_game()


func join_server(_address: String, _port: int):
	address = _address
	port = _port
	network_players = {}
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		print("Cannot create client: " + error_string(error))
		reset_game()
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)


func host_server(_port: int) -> bool:
	address = "localhost"
	port = _port
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 8)
	if error != OK:
		print("Cannot host: " + error_string(error))
		reset_game()
		return false
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	network_players = {}
	game_state = GameState.LOBBY
	print("Waiting for network_players")
	if is_player:
		_on_connected_to_server()
	return true


func update_my_network_player():
	update_network_player.rpc(my_network_player.to_dict())


@rpc("any_peer", "call_local", "reliable")
func update_network_player(network_player_dict: Dictionary):
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id():
		var network_player = NetworkPlayer.from_dict(network_player_dict)
		network_players[network_player.multiplayer_id] = network_player
	network_players_updated.emit()


@rpc("authority", "call_local", "reliable")
func kick_player(reason: String):
	print("Kicked from game: ", reason)
	reset_game()


func get_player(player_id: int) -> NetworkPlayer:
	return network_players[player_id] as NetworkPlayer


func client_to_server_time(client_time: float):
	return client_time + server_client_time_offset


func reset_game():
	if peer and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		peer.close()
	peer = null
	multiplayer.set_multiplayer_peer(null)
	network_players.clear()
	game_reseted.emit()
	game_state = GameState.IDLE
	average_rtt = 0


func _process(delta):
	if game_state != GameState.IDLE and not multiplayer.is_server():
		_ping_timer -= delta
		if _ping_timer <= 0:
			_ping.rpc_id(1, Time.get_ticks_msec())
			_ping_timer = ping_interval


@rpc("any_peer", "call_remote", "reliable")
func _ping(start_time: float):
	_ping_response.rpc_id(multiplayer.get_remote_sender_id(), start_time, Time.get_ticks_msec())


@rpc("authority", "call_remote", "reliable")
func _ping_response(start_time: float, _server_time: float):
	var end_time = Time.get_ticks_msec()
	_ping_samples.push_back(end_time - start_time)
	if _ping_samples.size() > ping_sample_count:
		_ping_samples.remove_at(0)
	average_rtt = 0
	for sample in _ping_samples:
		average_rtt += sample
	average_rtt /= _ping_samples.size()
	server_client_time_offset = _server_time + average_rtt - client_time


func _on_peer_connected(id: int):
	print("Peer connected ", id)
	if multiplayer.is_server():
		if game_state != GameState.LOBBY:
			kick_player.rpc_id(id, "Game already in progress")
			return
	update_network_player.rpc_id(id, my_network_player.to_dict())


func _on_peer_disconnected(id: int):
	print("Peer disconnected ", id)
	network_players.erase(id)
	network_players_updated.emit()
	
	if game_state == GameState.IN_GAME:
		# tODO: Handle quitting mid game gracefully
		reset_game()


func _on_connected_to_server():
	print("Connected to server")
	# Send all clients your info
	var my_network_player = NetworkPlayer.new()
	my_network_player.multiplayer_id = multiplayer.get_unique_id()
	my_network_player.readied_up = false
	my_network_player.username = "Player" + str(multiplayer.get_unique_id())
	network_players[my_network_player.multiplayer_id] = my_network_player
	update_my_network_player()
	connected_to_server.emit()


func _on_connection_failed():
	print("Connection to server failed")
	reset_game()


func _on_server_disconnected():
	print("Server disconnected")
	reset_game()


@rpc("any_peer", "call_local", "reliable")
func ready_up():
	var readied_player_id = multiplayer.get_remote_sender_id()
	print("Readied player %s up" % readied_player_id)
	if multiplayer.get_unique_id() == readied_player_id:
		print("  (Readied self up)")
	get_player(readied_player_id).readied_up = true
	network_players_updated.emit()
	if multiplayer.is_server() and _readied_player_count == network_players.size() and _all_unique_usernames():
		start_game.rpc()


func _all_unique_usernames():
	var names_dict = {}
	for player: NetworkPlayer in network_players.values():
		if player.username in names_dict:
			return false
		names_dict[player.username] = null
	return true


@rpc("authority", "call_local", "reliable")
func start_game():
	print("Game started")
	game_state = GameState.IN_GAME
	var arr: Array[NetworkPlayer] = []
	arr.assign(network_players.values())
	game_started.emit(arr)
