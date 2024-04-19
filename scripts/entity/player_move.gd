class_name PlayerMove
extends Node


const MAX_MOVE_AND_SLIDES: int = 10


@export var speed: float = 500;
@export var visuals: Sprite2D
@export var input: PlayerInput
@export var collision_shape: CollisionShape2D
## Factor that contorls How much player's position
## can deviate from server position at a given latency 
@export var position_slack_factor: float = 1
## Minimum distance of slack the player is given
@export var position_slack_min: float = 32
## How long it takes for the player 
## to start detecting position desyncs
## after the player has stopped inputting
## a direction
@export var position_desync_kickin_duration: float = 1.0
## Maximum number of seconds of position desync before
## the player is rubberbanded back to their correct position
@export var position_desync_duration_factor: float = 0.0025
@export var position_desync_duration_min: float = 0.5

@onready var player: Player = get_parent()

var server_position: Vector2
var direction: Vector2

var network_manager: NetworkManager
var game_manager: GameManager

var _interpolate_timer: float = -1
var _interpolate_duration: float
var _interpolate_dest: Vector2
var _interpolate_start_pos: Vector2
var _is_interpolating: bool :
	get:
		return _interpolate_timer > 0
var _position_desync_kickin_timer: float = -1
var _position_desync_timer: float = -1
var _is_position_desynced: bool :
	get:
		return _position_desync_timer >= 0
var _is_detecting_position_desyncs: bool


func _ready():
	network_manager = NetworkManager.instance
	game_manager = GameManager.instance
	game_manager.game_ticked.connect(_on_game_ticked)
	set_physics_process(player.is_controlling_player)
	# We want to give the collision shape some
	# leeway if we're the server in charge of simulating
	# the game state.
	#
	# However if we are also controlling a player as the
	# server, we don't want to give our own player leeway
	if network_manager.is_headless_server or (not player.is_controlling_player and network_manager.is_player_server):
		(collision_shape.shape as CircleShape2D).radius *= 0.9
	if not player.is_controlling_player:
		if not network_manager.is_server:
			# If we are not controlling the player and are not the server,
			# we don't need to worry about the collision of other players 
			collision_shape.disabled = true
		_start_interpolate_to_server_pos()


func _start_interpolate_to_server_pos():
	var start_pos = visuals.global_position if network_manager.is_player_server else player.global_position
	var dist_to_dest = start_pos.distance_to(server_position)
	if dist_to_dest > 0:
		_interpolate_start_pos = start_pos
		_interpolate_dest = server_position
		_interpolate_duration = game_manager.tick_interval
		_interpolate_timer = _interpolate_duration


func _on_game_ticked():
	if multiplayer.is_server():
		_sync_to_clients.rpc(player.global_position, direction)
	elif network_manager.is_player and player.is_controlling_player:
		_sync_to_server.rpc_id(1, player.global_position, direction)


func _process(delta):	
	if _interpolate_timer >= 0:
		_interpolate_timer -= delta
		var amount = clampf(1.0 - _interpolate_timer / _interpolate_duration, 0.0, 1.0)
		if network_manager.is_player_server and not player.is_controlling_player:
			visuals.global_position = _interpolate_start_pos.lerp(_interpolate_dest, amount)
		else:
			player.global_position = _interpolate_start_pos.lerp(_interpolate_dest, amount)
		if _interpolate_timer < 0:
			if network_manager.is_player_server and not player.is_controlling_player:
				visuals.global_position = _interpolate_dest
			else:
				player.global_position = _interpolate_dest
	if _position_desync_kickin_timer >= 0:
		_position_desync_kickin_timer -= delta
		if _position_desync_kickin_timer < 0:
			_is_detecting_position_desyncs = true
	if _position_desync_timer >= 0:
		_position_desync_timer -= delta
		if _position_desync_timer < 0:
			print("Force Sync: _position_desync_timer is up")
			## Force a resync if we desync too much
			_start_interpolate_to_server_pos()


func _physics_process(delta):
	# Run if we are client controlling this player
	# Don't run when we're being tweened, because that
	# means we're getting our position corrected
	if _is_interpolating:
		return
	
	direction = input.move_direction
	player.velocity = direction * speed

	player.move_and_slide()
	
	if network_manager.is_player_server:
		server_position = player.global_position
	var allowable_position_desync = max(position_slack_factor * network_manager.average_latency_ms, position_slack_min) * game_manager.tick_interval * speed
	var dist_to_server_pos = player.global_position.distance_squared_to(server_position)
	if direction.length_squared() == 0:
		if not _is_detecting_position_desyncs and _position_desync_kickin_timer < 0:
			_position_desync_kickin_timer = position_desync_kickin_duration
	elif (_is_detecting_position_desyncs or _position_desync_kickin_timer > 0):
		# If we started doing inputs again, then we stop detecting position desyncs
		_is_detecting_position_desyncs = false
		_position_desync_kickin_timer = -1
	if _is_detecting_position_desyncs and dist_to_server_pos > 0.01:
		# If we are not moving, then start desync timer
		if not _is_position_desynced:
			# Turn on the desync timer
			_position_desync_timer = max(position_desync_duration_factor * network_manager.average_latency_ms, position_desync_duration_min) * game_manager.tick_interval * speed
	else:
		# Turn off the desync timer if we're synced again
		_position_desync_timer = -1
	if dist_to_server_pos > allowable_position_desync * allowable_position_desync:
		print("Force Sync: dist_to_server_pos > allowable_position_desync")
		## Force a resync if we desync too much
		_start_interpolate_to_server_pos()


@rpc("any_peer", "call_remote", "reliable")
func _sync_to_server(source_position: Vector2, source_direction: Vector2):
	var motion = source_position - player.global_position
	var orig_visual_position = visuals.global_position
	var collision = player.move_and_collide(motion)
	var slide_count = 0
	while collision and collision.get_remainder().length_squared() > 0 and slide_count < MAX_MOVE_AND_SLIDES: 
		var angle = collision.get_normal().angle_to(motion)
		if angle == 0:
			break
		elif sign(angle) > 0:
			angle = deg_to_rad(90) - angle
		else:
			angle = deg_to_rad(-90) - angle
		motion = collision.get_remainder().rotated(angle)
		#print("motion angle: ", rad_to_deg(motion.angle()), " remainder angle: ", rad_to_deg(collision.get_remainder().angle()))
		#motion = collision.get_remainder()
		collision = player.move_and_collide(motion)
		slide_count += 1
	server_position = player.global_position
	direction = source_direction
	if network_manager.is_player_server:
		visuals.global_position = orig_visual_position
		_start_interpolate_to_server_pos()


@rpc("authority", "call_remote", "reliable")
func _sync_to_clients(source_position: Vector2, source_direction: Vector2):
	server_position = source_position
	if not player.is_controlling_player:
		direction = source_direction
		_start_interpolate_to_server_pos()
