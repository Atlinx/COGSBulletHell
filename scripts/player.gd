class_name Player
extends CharacterBody2D


@export var speed: float = 100;
@export var camera: Camera2D
@export var sync_interval: float = 1/10.0
@export var interpolate_factor: float = 1
@export var interpolate_curve: Curve
## Factor that contorls How much player's position
## can deviate from server position at a given latency 
@export var position_slack_factor: float = 64
## Minimum distance of slack the player is given
@export var position_slack_min: float = 32
## Maximum number of seconds of position desync before
## the player is rubberbanded back to their correct position
@export var position_desync_duration: float = 5

var server_position: Vector2
var direction: Vector2

var network_player: NetworkManager.NetworkPlayer
var network_manager: NetworkManager
var is_controlling_player: bool :
	get:
		return network_player.multiplayer_id == multiplayer.get_unique_id()

var _sync_timer: float = 0
var _interpolate_tween: Tween
var _interpolate_timer: float = -1
var _interpolate_duration: float
var _interpolate_dest: Vector2
var _interpolate_start_pos: Vector2
var _is_interpolating: bool :
	get:
		return _interpolate_timer > 0


func construct(_network_player: NetworkManager.NetworkPlayer):
	network_player = _network_player


func _ready():
	network_manager = NetworkManager.instance
	name = "Player" + str(network_player.multiplayer_id)
	camera.enabled = is_controlling_player
	set_physics_process(is_controlling_player)
	if not is_controlling_player:
		_start_interpolate_to_server_pos()


func _start_interpolate_to_server_pos():
	var dist_to_dest = global_position.distance_to(server_position)
	if dist_to_dest > 0.01:
		_interpolate_start_pos = global_position
		_interpolate_dest = server_position
		_interpolate_duration = dist_to_dest / 128.0 * sync_interval * interpolate_factor
		print("interpolate duration: ", _interpolate_duration)
		_interpolate_timer = _interpolate_duration


func _process(delta):
	if _sync_timer >= 0:
		_sync_timer -= delta
		if _sync_timer < 0:
			_sync_timer = sync_interval	
			if multiplayer.is_server():
				_sync_to_clients.rpc(server_position, direction)
			elif network_manager.is_player and is_controlling_player:
				_sync_to_server.rpc_id(1, global_position, direction)
	if _interpolate_timer >= 0:
		_interpolate_timer -= delta
		var amount = interpolate_curve.sample(1.0 - _interpolate_timer / _interpolate_duration)
		global_position = _interpolate_start_pos.lerp(_interpolate_dest, amount)
		if _interpolate_timer < 0:
			global_position = _interpolate_dest


func _physics_process(delta):
	# Run if we are client controlling this player
	# Don't run when we're being tweened, because that
	# means we're getting our position corrected
	if _is_interpolating:
		return
	
	direction = Input.get_vector("player_left", "player_right", "player_up", "player_down").normalized()
	velocity = direction * speed

	move_and_slide()
	
	var allowable_position_desync = max(position_slack_factor * network_manager.average_latency, position_slack_min * sync_interval) * speed 
	if global_position.distance_squared_to(server_position) > allowable_position_desync * allowable_position_desync:
		print("Forced desync")
		## Force a resync if we desync too much
		_start_interpolate_to_server_pos()


@rpc("any_peer", "call_remote", "reliable")
func _sync_to_server(source_position: Vector2, source_direction: Vector2):
	print("sync to server: ", name, " : ", source_position)
	server_position = global_position
	var motion = source_position - global_position
	move_and_collide(motion)
	direction = source_direction


@rpc("authority", "call_remote", "reliable")
func _sync_to_clients(source_position: Vector2, source_direction: Vector2):
	server_position = source_position
	if not is_controlling_player:
		direction = source_direction
		_start_interpolate_to_server_pos()
