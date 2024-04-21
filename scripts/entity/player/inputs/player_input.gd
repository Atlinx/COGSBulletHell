class_name PlayerInput
extends Node


signal on_primary_used
signal on_secondary_used
signal on_utility_used
signal on_special_used


@export var aim_direction: Vector2 = Vector2.RIGHT :
	get:
		return aim_direction
	set(value):
		if value != Vector2.ZERO:
			aim_direction = value.normalized()
@export var move_direction: Vector2
@export var is_using_primary: bool :
	get:
		return is_using_primary
	set(value):
		if value != is_using_primary:
			is_using_primary = value
			print("using primary changed: ", is_using_primary)
			if is_using_primary:
				print("  emit primary used")
				on_primary_used.emit()
@export var is_using_secondary: bool :
	get:
		return is_using_secondary
	set(value):
		if value != is_using_secondary:
			is_using_secondary = value
			if is_using_secondary:
				on_secondary_used.emit()
@export var is_using_utility: bool :
	get:
		return is_using_utility
	set(value):
		if value != is_using_utility:
			is_using_utility = value
			if is_using_utility:
				on_utility_used.emit()
@export var is_using_special: bool :
	get:
		return is_using_special
	set(value):
		if value != is_using_special:
			is_using_special = value
			if is_using_special:
				on_special_used.emit()


var network_manager: NetworkManager
var game_manager: GameManager

@onready var player: Player = get_parent()


func _ready():
	set_process(player.is_controlling_player)
	network_manager = NetworkManager.instance
	game_manager = GameManager.instance
	game_manager.game_ticked.connect(_on_game_ticked)


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
