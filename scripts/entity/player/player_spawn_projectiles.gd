class_name PlayerSpawnProjectiles
extends Node


@export var spawn_projectiles: SpawnProjectiles
@export var player: Player

var network_manager: NetworkManager
var manual_player: ManualPlayer
var player_move: PlayerMove


func _ready():
	network_manager = NetworkManager.instance
	manual_player = player.get_node_or_null("ManualPlayer") as ManualPlayer
	player_move = player.get_node("PlayerMove") as PlayerMove


# Used for spawning projectiles in abilities
func _send_ability_data(data: Dictionary):
	data.muzzle_position = spawn_projectiles.muzzle.global_position
	data.muzzle_rotation = spawn_projectiles.muzzle.global_rotation


# Used for spawning projectiles in abilities
func _receive_ability_data(data: Dictionary):
	if manual_player:
		# Perform verification
		var muzzle_sqr_dist = (data.muzzle_position as Vector2).distance_squared_to(spawn_projectiles.muzzle.global_position)
		if not network_manager.is_acceptable_position_diff(manual_player.multiplayer_id, muzzle_sqr_dist, player_move.speed):
			return
	spawn_projectiles.muzzle.global_position = data.muzzle_position
	spawn_projectiles.muzzle.global_rotation = data.muzzle_rotation
	spawn_projectiles.spawn()
