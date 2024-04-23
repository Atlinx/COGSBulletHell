## Player input that can swap between
## keyboard and controller controls
class_name KeyboardControllerPlayerInput
extends Node


signal mode_changed(new_mode: Mode)

enum Mode {
	MOUSE_KEYBOARD,
	CONTROLLER
}

var _mouse_inside: bool = true
var joy_device_id: int
var mode: Mode :
	get:
		return mode
	set(value):
		mode = value
		mode_changed.emit(value)

var manual_player: ManualPlayer
var player_input: PlayerInput


func _ready():
	manual_player = get_parent() as ManualPlayer
	player_input = manual_player.player.get_node("PlayerInput")
	set_process(manual_player.is_controlling_player)
	if manual_player.is_controlling_player:
		Input.joy_connection_changed.connect(_on_joy_connection_changed)
		_update_joypad_id()


func _on_joy_connection_changed(device: int, connected: bool):
	_update_joypad_id()


func _update_joypad_id():
	var joy_pads = Input.get_connected_joypads()
	joy_device_id = -1
	if manual_player.game_player.network_player_index >= 0:
		if joy_pads.size() > manual_player.game_player.network_player_index:
			joy_device_id = Input.get_connected_joypads()[manual_player.game_player.network_player_index]


func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_ENTER:
		_mouse_inside = true
	elif what == NOTIFICATION_WM_MOUSE_EXIT:
		_mouse_inside = false


func _process(delta):
	# Moving
	var move_direction = Vector2.ZERO
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
	player_input.move_direction = move_direction
	
	# Primary
	player_input.is_using_primary = (_mouse_inside and Input.is_action_pressed("player_primary")) or (Input.get_joy_axis(joy_device_id, JOY_AXIS_TRIGGER_RIGHT) > 0.5)
	
	# Secondary
	player_input.is_using_secondary = (_mouse_inside and Input.is_action_pressed("player_secondary")) or (Input.get_joy_axis(joy_device_id, JOY_AXIS_TRIGGER_LEFT) > 0.5)
	
	# Utility
	player_input.is_using_utility = (_mouse_inside and Input.is_action_pressed("player_secondary")) or (Input.is_joy_button_pressed(joy_device_id, JOY_BUTTON_LEFT_SHOULDER))
	
	# Special
	player_input.is_using_special = (_mouse_inside and Input.is_action_pressed("player_special")) or (Input.is_joy_button_pressed(joy_device_id, JOY_BUTTON_RIGHT_SHOULDER))
	
	# Aiming
	if mode == Mode.MOUSE_KEYBOARD:
		player_input.aim_direction = (player_input.player.get_global_mouse_position() - player_input.player.global_position).normalized()
	else:
		var stick_direction = Vector2(Input.get_joy_axis(joy_device_id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(joy_device_id, JOY_AXIS_RIGHT_Y))
		if stick_direction.length_squared() > 0.5 * 0.5:
			player_input.aim_direction = stick_direction.normalized()
	
	# Zoom
	if Input.is_action_just_pressed("player_zoom_in"):
		manual_player.camera_zoom *= 1.1
	elif Input.is_action_just_pressed("player_zoom_out"):
		manual_player.camera_zoom /= 1.1
