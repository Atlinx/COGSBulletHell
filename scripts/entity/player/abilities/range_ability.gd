class_name RangeAbility
extends Node


signal used
signal cooldown_used


@export var marker: Node2D
@export var select_range: float = 500
@export var select_duration: float = 5
@export var select_curve: Curve
@export var player: Node2D
@export var player_input: PlayerInput
@export var player_move: PlayerMove

@onready var ability: PlayerAbility = get_parent()
var network_manager: NetworkManager
var manual_player: ManualPlayer

var _select_timer: float
var _waiting_for_pressed: bool


func _ready():
	marker.visible = false
	ability.used_pressed.connect(_on_used_pressed)
	ability.used_released.connect(_on_used_released)
	network_manager = NetworkManager.instance
	manual_player = player.get_node_or_null("ManualPlayer")
	set_process(false)


func _on_used_pressed():
	if ability.on_cooldown:
		return
	marker.global_position = player.global_position
	marker.visible = true
	_select_timer = 0
	_waiting_for_pressed = false
	set_process(true)


func _on_used_released():
	marker.visible = false
	set_process(false)
	
	if ability.on_cooldown or _waiting_for_pressed:
		return
	
	_waiting_for_pressed = true
	var data = {
		"position": marker.global_position
	}
	for child in get_children():
		if child.has_method("_send_ability_data"):
			child._send_ability_data(data)
	if multiplayer.is_server():
		_use_server(network_manager.server_time, data)
	else:
		print("req use server")
		_use_server.rpc_id(1, network_manager.server_time, data)
		ability.start_cooldown()
		used.emit()


func _process(delta):
	_select_timer += delta
	var amount = clampf(_select_timer / select_duration, 0, 1)
	var distance = select_curve.sample(amount) * select_range
	marker.global_position = player.global_position + player_input.aim_direction * distance
	if _select_timer >= select_duration:
		_waiting_for_pressed = true
		_on_used_released()


@rpc("any_peer", "call_remote", "reliable")
func _use_server(start_time: float, data: Dictionary):
	print("use server")
	var diff = network_manager.server_time - start_time
	if manual_player:
		# Perform verification
		var range_sqr_dist = (data.position as Vector2).distance_squared_to(player.position)
		if not network_manager.is_acceptable_position_diff(manual_player.multiplayer_id, range_sqr_dist, player_move.speed, select_range):
			return
	if ability.on_cooldown:
		cooldown_used.emit()
		return
	for child in get_children():
		if child.has_method("_receive_ability_data"):
			child._receive_ability_data(data)
	# Make cooldown run a little faster on server to avoid cases where client tries to
	# use ability and it was still barely on cooldown.
	ability.start_cooldown(diff + network_manager.get_player(manual_player.multiplayer_id).average_rtt * 2)
	used.emit()
