class_name BasicAbility
extends Node


## Called when the ability is used during cooldown
signal cooldown_used
## Called when ability is used
signal used

@export var use_on_pressed: bool = true
@export var use_on_released: bool = true
## Tries to use the ability every frame
## that the ability button is pressed.
##
## If enabled, this disables the cooldown_used signal.
@export var use_while_pressed: bool = true
@export var player: Player


@onready var ability: PlayerAbility = get_parent()
var network_manager: NetworkManager
var manual_player: ManualPlayer


func _ready():
	network_manager = NetworkManager.instance
	manual_player = player.get_node_or_null("ManualPlayer")
	if use_on_pressed:
		ability.used_pressed.connect(use)
	if use_on_released:
		ability.used_released.connect(use)
	set_process(use_while_pressed)


func use():
	if use_while_pressed and ability.on_cooldown:
		# If we are using while pressed, then we don't track cooldown used
		return
	var data = {}
	for child in get_children():
		if child.has_method("_send_ability_data"):
			child._send_ability_data(data)
	if multiplayer.is_server():
		_use_server(network_manager.server_time, data)
	else:
		_use_server.rpc_id(1, network_manager.server_time, data)
		ability.start_cooldown()
		used.emit()


# TODO: Replace any_peer to appropriate authority
# Right now, any player can also control any other player through
# arbitrary rpc calls
@rpc("any_peer", "call_remote", "reliable")
func _use_server(start_time: float, data: Dictionary):
	var diff = network_manager.server_time - start_time
	if manual_player and not network_manager.is_acceptable_time_diff(manual_player.multiplayer_id, diff):
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


func _process(_delta):
	if ability.is_used_pressed:
		use()
