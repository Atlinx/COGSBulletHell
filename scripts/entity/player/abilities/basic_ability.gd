class_name BasicAbility
extends Node


## Called when the ability is used during cooldown
signal cooldown_used
## Called when ability is used
signal used

@export var use_on_pressed: bool = true
@export var use_on_released: bool = true
@export var use_while_pressed: bool = true
@export var player: Player


@onready var ability: PlayerAbility = get_parent()
var network_manager: NetworkManager


func _ready():
	network_manager = NetworkManager.instance
	if use_on_pressed:
		ability.used_pressed.connect(use)
	if use_on_released:
		ability.used_released.connect(use)
	set_process(use_while_pressed)


func use():
	if ability.on_cooldown:
		cooldown_used.emit()
		return
	ability.start_cooldown()
	var data = {}
	for child in get_children():
		if child.has_method("_send_ability_data"):
			child._send_ability_data(data)
	if multiplayer.is_server():
		_use_server(network_manager.server_time, data)
	else:
		_use_server.rpc_id(1, network_manager.server_time, data)
	used.emit()


# TODO: Replace any_peer to appropriate authority
# Right now, any player can also control any other player through
# arbitrary rpc calls
@rpc("any_peer", "call_local", "reliable")
func _use_server(start_time: float, data: Dictionary):
	var diff = network_manager.server_time - start_time
	if not network_manager.is_acceptable_time_diff(diff) or ability.on_cooldown:
		return
	for child in get_children():
		if child.has_method("_receive_ability_data"):
			child._receive_ability_data(data)
	ability.start_cooldown(diff)
	var old_pos = player.global_position
	player.global_position = player.global_position

	# Only run sim on server
	for child in get_children():
		if child is SpawnProjectiles:
			child.spawn()


func _process(delta):
	if ability.is_used_pressed:
		use()
