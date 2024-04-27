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
@export var max_players: int = 8
@export_group("Verification")
@export var acceptable_time_diff_factor: float = 50 # ms
@export var acceptable_time_diff_min: float = 16 # ms
@export var acceptable_position_diff_factor: float = 0.2 # pixels * ms
@export var acceptable_position_diff_min: float = 32 # pixels
@export var max_unacknowledged_ping_time: float = 3

var peer: ENetMultiplayerPeer
var game_state: GameState = GameState.IDLE

var is_player_server: bool :
	get:
		return is_player and is_server
var is_headless_server: bool = false
var is_player: bool :
	get:
		return not is_headless_server
var is_server: bool :
	get:
		if multiplayer:
			return multiplayer.is_server()
		return false
var can_ready_up: bool :
	get:
		return _all_unique_usernames()

# SECONDS DATA
## Round trip time (Two-way delay between client and server) in seconds
var average_rtt: float :
	get:
		return average_rtt / 1000
## One-way delay between client and server in seconds
var average_latency: float :
	get:
		return average_latency_ms / 1000
## Time of the server in seconds
var server_time: float :
	get:
		return server_time_ms / 1000
## Time of the client in seconds
var client_time: float :
	get:
		return client_time_ms / 1000
## Offset between server and client time in seconds
## client_time_ms + server_time_offset_ms = server_time_ms
var server_time_offset: float :
	get:
		return server_time_offset_ms / 1000

# MILLISECONDS DATA (ORIGINAL)
## Round trip time (Two-way delay between client and server) in msecs
var average_rtt_ms: float
## One-way delay between client and server in msecs
var average_latency_ms: float :
	get:
		return average_rtt_ms / 2.0
## Time of the server in msecs
var server_time_ms: float :
	get:
		return client_time_ms + server_time_offset_ms
## Time of the client in msecs
var client_time_ms: float
## Offset between server and client time in msecs
## client_time_ms + server_time_offset_ms = server_time_ms
var server_time_offset_ms: float

## Is my own player a bot?
var is_self_bot: bool


var _ping_timer: float
## Used by client to track average latency to server
var _rtt_samples: PackedFloat32Array
var _readied_player_count: int :
	get:
		var count = 0
		for player: NetworkPlayer in network_players.values():
			if player.readied_up:
				count += 1
		return count
## Whether the client's connection to the server was approved
## Connectins are only approved when the server is in the lobby 
## and waiting for new players.
var _connection_approved: bool
## Used by server to keep track of individual ping packets
var _ping_id: int
## Dictionary of peers waiting to be approved
## [peer_id: int]: { [peer_id]: null } (Peers that have received it's approval)
var _peers_waiting_approval: Dictionary = {}

class NetworkPlayer extends RefCounted:
	var multiplayer_id: int
	var username: String
	var is_bot: bool
	var readied_up: bool
	var average_rtt: float :
		get:
			return average_rtt_ms / 1000
	var average_latency: float :
		get:
			return average_latency_ms / 1000
	## Only used by the server to keep track of client rtt
	var average_rtt_ms: float
	var average_latency_ms: float :
		get:
			return average_rtt_ms / 2.0
	## Used by server to calculate RTT for clients
	var rtt_samples: PackedFloat32Array
	## Used by server to keep track of last acknowledged ping packet
	var last_acknowledged_ping_id: int = -1
	## Used by server to keep track of unacknowledged ping packet and 
	## their start times
	## [ping_id: int]: float (ping start time)
	var unacknowledged_pings: Dictionary
	
	
	func update_rtt(rtt_ms: float, ping_sample_limit: int):
		rtt_samples.push_back(rtt_ms)
		if rtt_samples.size() > ping_sample_limit:
			rtt_samples.remove_at(0)
		average_rtt_ms = 0
		for sample in rtt_samples:
			average_rtt_ms += sample
		average_rtt_ms /= rtt_samples.size()
	
	
	func to_dict() -> Dictionary:
		return {
			"multiplayer_id": multiplayer_id,
			"username": username,
			"is_bot": is_bot,
			"readied_up": readied_up
		}
	
	func from_dict(dict: Dictionary):
		multiplayer_id = dict.get("multiplayer_id")
		username = dict.get("username")
		readied_up = dict.get("readied_up")
		is_bot = dict.get("is_bot")


# [multiplayer_id: int]: NetworkPlayer
var network_players: Dictionary
var network_players_list: Array[NetworkPlayer]:
	get:
		var arr: Array[NetworkPlayer] = []
		arr.assign(network_players.values())
		return arr
var network_players_sorted_list: Array[NetworkPlayer]:
	get:
		var _network_players_list = network_players_list
		_network_players_list.sort_custom(func (a: NetworkManager.NetworkPlayer, b: NetworkManager.NetworkPlayer): return a.multiplayer_id < b.multiplayer_id)
		return _network_players_list
var my_network_player: NetworkPlayer:
	get:
		return network_players.get(multiplayer.get_unique_id())


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
	is_headless_server = "--server" in OS.get_cmdline_args()
	if is_headless_server:
		host_server(port)


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if instance == self:
			instance = null


func _ready():
	reset_game()


func join_server(_address: String, _port: int):
	if _port < 1 or _port > 65535:
		print("Port is invalid")
		reset_game()
		return
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
		_on_connection_to_server_approved([])
	return true


func update_my_network_player():
	update_network_player.rpc(my_network_player.to_dict())


@rpc("any_peer", "call_local", "reliable")
func update_network_player(network_player_dict: Dictionary):
	var multiplayer_id = network_player_dict.get("multiplayer_id")
	if not multiplayer_id in network_players or multiplayer_id != multiplayer.get_remote_sender_id():
		# Don't accept network players from unapproved peers
		# Only approved peers will exist in the network_player_dict
		#
		# Don't let peers modify NetworkPlayers that aren't their own
		return
	if multiplayer.get_remote_sender_id() != multiplayer.get_unique_id():
		# We're receiving someone else's network player update
		get_player(multiplayer_id).from_dict(network_player_dict)
	network_players_updated.emit()


@rpc("authority", "call_local", "reliable")
func kick_player(reason: String):
	print("Kicked from game: ", reason)
	reset_game()


func get_player(player_id: int) -> NetworkPlayer:
	return network_players[player_id] as NetworkPlayer


func client_to_server_time(_client_time_ms: float):
	return _client_time_ms + server_time_offset_ms


## Checks if a client and server time difference is within
## acceptable levels. 
##
## This is used for netcode that requires clients to send 
## their start time of a given action. We don't want
## client to spoof their start time too far back in the past
## or to spoof their time into the future. 
func is_acceptable_time_diff(peer_id: int, time_diff: float) -> bool:
	return is_acceptable_time_diff_ms(peer_id, time_diff * 1000)


## Checks if a client and server time difference is within
## acceptable levels. 
##
## This is used for netcode that requires clients to send 
## their start time of a given action. We don't want
## client to spoof their start time too far back in the past
## or to spoof their time into the future. 
func is_acceptable_time_diff_ms(peer_id: int, time_diff_ms: float) -> bool:
	var time_diff_limit = acceptable_time_diff_ms(peer_id)
	if abs(time_diff_ms) >= time_diff_limit:
		print("Unacceptable time diff: ", time_diff_ms, " abs limit: ", time_diff_limit)
	return abs(time_diff_ms) < time_diff_limit


## Returns the allowable time difference between
## a client and server entity.
##
## This is used for netcode that requires clients to send 
## their start time of a given action. We don't want
## client to spoof their start time too far back in the past
## or to spoof their time into the future. 
func acceptable_time_diff(peer_id: int) -> float:
	return acceptable_time_diff_ms(peer_id) / 1000


## Returns the allowable time difference between
## a client and server entity.
##
## This is used for netcode that requires clients to send 
## their start time of a given action. We don't want
## client to spoof their start time too far back in the past
## or to spoof their time into the future. 
func acceptable_time_diff_ms(peer_id: int) -> float:
	return max(get_player(peer_id).average_latency_ms * acceptable_time_diff_factor, acceptable_time_diff_min)


## Checks if a client and server entity's position difference is within
## acceptable levels, given the speed the entity was traveling at.
##
## This is used for netcode that requires clients to send 
## their start position of a given action. We don't want
## client to spoof their start position to far from
## their current position. 
func is_acceptable_position_diff(peer_id: int, position_diff_sqr: float, speed: float, instant_buffer: float = 0) -> bool:
	var factor = acceptable_position_diff(peer_id, speed, instant_buffer)
	if position_diff_sqr >= factor * factor:
		print("Unacceptable position diff: ", sqrt(position_diff_sqr), " >= factor: ", factor, " given speed: ", speed, " buffer: ", instant_buffer)
	return position_diff_sqr < factor * factor


## Returns the allowable position difference
## between a client and server entity, given a speed.
##
## This is used for netcode that requires clients to send 
## their start position of a given action. We don't want
## client to spoof their start position to far from
## their current position. 
func acceptable_position_diff(peer_id: int, speed: float, instant_buffer: float = 0) -> float:
	return max(get_player(peer_id).average_latency_ms * acceptable_position_diff_factor * speed, acceptable_position_diff_min) + instant_buffer


func reset_game():
	if peer and peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()
	peer = null
	network_players.clear()
	game_reseted.emit()
	game_state = GameState.IDLE
	average_rtt_ms = 0
	server_time_offset_ms = 0
	_connection_approved = false
	_peers_waiting_approval = {}
	is_self_bot = false


func _process(delta):
	client_time_ms += delta * 1000
	if game_state != GameState.IDLE:
		if multiplayer.is_server():
			# Ping clients to establish latency
			_ping_timer -= delta
			if _ping_timer <= 0:
				_ping_prepare()
				_ping_timer = ping_interval


## Ping step 1: Server records new ping and send it to clients
func _ping_prepare():
	var start_time = client_time_ms
	for network_player: NetworkPlayer in network_players.values():
		if network_player.multiplayer_id == 1:
			continue
		network_player.unacknowledged_pings[_ping_id] = start_time
		var time_since_last_acknowledged = network_player.unacknowledged_pings.size() * ping_interval
		if time_since_last_acknowledged > max_unacknowledged_ping_time:
			kick_player.rpc_id(network_player.multiplayer_id, "Failed to acknowledge pings")
	_ping.rpc(_ping_id)
	_ping_id += 1


## Ping step 2: Client responds to ping request
@rpc("authority", "call_remote", "reliable")
func _ping(ping_id: int):
	_ping_response.rpc_id(1, client_time_ms, ping_id)


## Ping step 3: Server responds to client's response to the ping request, 
## which is received on the client
@rpc("any_peer", "call_remote", "reliable")
func _ping_response(start_time_ms: float, ping_id: int):
	var player = get_player(multiplayer.get_remote_sender_id())
	if not ping_id in player.unacknowledged_pings or ping_id != (player.last_acknowledged_ping_id + 1):
		kick_player.rpc_id(player.multiplayer_id, "Invalid ping response")
		return
	var rtt_ms = client_time_ms - player.unacknowledged_pings.get(ping_id)
	player.update_rtt(rtt_ms, ping_sample_count)
	player.unacknowledged_pings.erase(ping_id)
	player.last_acknowledged_ping_id += 1
	_ping_response_response.rpc_id(multiplayer.get_remote_sender_id(), start_time_ms, client_time_ms)


## Ping step 4: Client receives server's response
@rpc("authority", "call_remote", "reliable")
func _ping_response_response(start_time_ms: float, _server_time_ms: float):
	var rtt_ms = max(client_time_ms - start_time_ms, 0)
	_rtt_samples.push_back(rtt_ms)
	if _rtt_samples.size() > ping_sample_count:
		_rtt_samples.remove_at(0)
	average_rtt_ms = 0
	for sample in _rtt_samples:
		average_rtt_ms += sample
	average_rtt_ms /= _rtt_samples.size()
	server_time_offset_ms = _server_time_ms + average_latency_ms - client_time_ms


@rpc("authority", "call_remote", "reliable")
func _on_connection_to_server_approved(_network_players: Array):
	print("Connection to server approved")
	_connection_approved = true
	game_state = GameState.LOBBY
	for network_player: Dictionary in _network_players:
		var player = NetworkPlayer.new()
		player.from_dict(network_player)
		network_players[player.multiplayer_id] = player
	# Send all clients your info
	var _my_network_player = NetworkPlayer.new()
	_my_network_player.multiplayer_id = multiplayer.get_unique_id()
	_my_network_player.readied_up = false
	_my_network_player.username = "Player" + str(multiplayer.get_unique_id())
	_my_network_player.is_bot = is_self_bot
	network_players[_my_network_player.multiplayer_id] = _my_network_player
	update_my_network_player()
	connected_to_server.emit()


@rpc("authority", "call_remote", "reliable")
func _notify_peer_approved(peer_id: int):
	print("_notify_peer_approved: ", peer_id)
	var new_network_player = NetworkPlayer.new()
	new_network_player.multiplayer_id = peer_id
	network_players[peer_id] = new_network_player
	_notify_peer_approved_acknowledged.rpc_id(1, peer_id)


@rpc("any_peer", "call_local", "reliable")
func _notify_peer_approved_acknowledged(peer_id: int):
	if not multiplayer.get_remote_sender_id() in network_players:
		# We can't let unapproved peers approve themselves
		return
	if is_server:
		_peers_waiting_approval[peer_id][multiplayer.get_remote_sender_id()] = null
		if _peers_waiting_approval[peer_id].size() == network_players.size():
			# Everyone has received approval of the new peer,
			# and can now start interacting with it 
			_peers_waiting_approval.erase(peer_id)
			
			# Finally, we can send a connection approved message
			# to the new peer to tell them they can start talking
			# with other peers
			var _network_players = []
			for player in network_players_list:
				_network_players.append(player.to_dict())
			
			# Reset the ping ack counter since we've now approved of the player
			get_player(peer_id).last_acknowledged_ping_id = _ping_id - 1
			_on_connection_to_server_approved.rpc_id(peer_id, _network_players)


func _on_peer_connected(id: int):
	if not _connection_approved:
		return
	print("Peer connected ", id)
	if multiplayer.is_server():
		if game_state == GameState.LOBBY:
			if network_players.size() == max_players:
				kick_player.rpc_id(id, "Lobby is full")
				return
			_peers_waiting_approval[id] = { 1: null }
			_notify_peer_approved(id)
			# Notify existing peers that new peer has been approved
			_notify_peer_approved.rpc(id)
		else:
			kick_player.rpc_id(id, "Game already in progress")
			return


func _on_peer_disconnected(id: int):
	if not _connection_approved or not id in network_players:
		return
	print("Peer disconnected ", id)
	network_players.erase(id)
	network_players_updated.emit()
	
	if is_server and game_state == GameState.IN_GAME:
		# TODO: Handle quitting mid game gracefully
		reset_game()


func _on_connected_to_server():
	print("Connected to server")


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
		# Make sure the server always starts first
		start_game()
		start_game.rpc()


func _all_unique_usernames():
	var names_dict = {}
	for player: NetworkPlayer in network_players.values():
		if player.username in names_dict:
			return false
		names_dict[player.username] = null
	return true


@rpc("authority", "call_remote", "reliable")
func start_game():
	print("Game started")
	game_state = GameState.IN_GAME
	var arr: Array[NetworkPlayer] = []
	arr.assign(network_players.values())
	game_started.emit(arr)
