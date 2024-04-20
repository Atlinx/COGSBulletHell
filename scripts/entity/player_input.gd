class_name PlayerInput
extends Node


signal on_shoot
signal mode_changed(new_mode: Mode)


enum Mode {
	MOUSE_KEYBOARD,
	CONTROLLER
}


@export var aim_direction: Vector2
@export var move_direction: Vector2
@export var network_player_index: int
@export var is_shooting: bool
@export var network_manager: NetworkManager
@export var game_manager: GameManager

@onready var player: Player = get_parent()

var _mouse_inside: bool
var joy_device_id: int
var mode: Mode :
	get:
		return mode
	set(value):
		mode = value
		mode_changed.emit(value)


func _ready():
	set_process(player.is_controlling_player)
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	network_manager = NetworkManager.instance
	game_manager = GameManager.instance
	game_manager.game_ticked.connect(_on_game_ticked)
	_update_joypad_id()


func _on_joy_connection_changed(device: int, connected: bool):
	if (joy_device_id < 0 and connected) or (device == joy_device_id and not connected):
		_update_joypad_id()


func _update_joypad_id():
	var joy_pads = Input.get_connected_joypads()
	if player.game_player.network_player_index >= 0:
		if joy_pads.size() > player.game_player.network_player_index:
			joy_device_id = Input.get_connected_joypads()[player.game_player.network_player_index]


func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		_mouse_inside = true
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		_mouse_inside = false


func _process(delta):
	# Moving
	move_direction = Vector2.ZERO
	if joy_device_id >= 0:
		move_direction = Vector2(Input.get_joy_axis(joy_device_id, JOY_AXIS_LEFT_X), Input.get_joy_axis(joy_device_id, JOY_AXIS_LEFT_Y))
		if move_direction.length_squared() < 0.5 * 0.5:
			move_direction = Vector2.ZERO
		else:
			mode = Mode.CONTROLLER
	if move_direction.length_squared() == 0:
		move_direction = Input.get_vector("player_left", "player_right", "player_up", "player_down").normalized()
		if move_direction.length_squared() > 0:
			mode = Mode.MOUSE_KEYBOARD
	
	# Shooting
	var _is_shooting = false
	if _mouse_inside and Input.is_action_pressed("player_shoot"):
		_is_shooting = true
	if (Input.get_joy_axis(joy_device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5 or Input.get_joy_axis(joy_device_id, JOY_AXIS_TRIGGER_LEFT) > 0.5):
		if not _is_shooting:
			_is_shooting = true
	if _is_shooting and not is_shooting:
		is_shooting = _is_shooting
		on_shoot.emit()
	elif not _is_shooting and is_shooting:
		is_shooting = false 
	
	# Aiming
	if mode == Mode.MOUSE_KEYBOARD:
		aim_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	else:
		var stick_direction = Vector2(Input.get_joy_axis(joy_device_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(joy_device_id, JOY_AXIS_RIGHT_Y))
		if stick_direction.length_squared() > 0.5 * 0.5:
			aim_direction = stick_direction.normalized()


func _on_game_ticked():
	if not network_manager.is_server:
		_sync_to_server.rpc_id(1, move_direction, aim_direction)
	elif network_manager.is_player_server:
		_sync_to_clients.rpc(move_direction, aim_direction)


@rpc("any_peer", "call_remote", "reliable")
func _sync_to_server(_move_direction: Vector2, _aim_direction: Vector2):
	move_direction = _move_direction
	aim_direction = _aim_direction
	_sync_to_clients.rpc(move_direction, aim_direction)


@rpc("authority", "call_remote", "reliable")
func _sync_to_clients(_move_direction: Vector2, _aim_direction: Vector2):
	move_direction = _move_direction
	aim_direction = _aim_direction
