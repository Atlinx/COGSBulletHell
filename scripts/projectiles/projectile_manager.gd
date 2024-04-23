class_name ProjectileManager
extends Node


signal on_spawn


@export var prefix: String
@export var team: Team
## Caches the team information on ready in local_dat.
## Should only be used if the team is not expected to change
@export var cache_team: bool = true
@export var prefabs: Array[PackedScene]
# Max projectiles that can be on screen
# After counter reaches projectiles_limit,
# it rolls over back to 0
@export var projectiles_limit = 1000

var network_manager: NetworkManager
var world: World
var counter: int
## Local data that is copied to spawned projectiles
@export var _local_data: Dictionary = {}
var local_data: Dictionary = {}


func _ready():
	local_data.merge(_local_data)
	world = World.instance
	network_manager = NetworkManager.instance
	if cache_team and team:
		local_data.team = team.team
		local_data.entity_owner = team.entity_owner.get_path() if is_instance_valid(team.entity_owner) else null
		local_data.entity_owner_data = team.entity_owner_data
		print("local data: ", JSON.stringify(local_data, "  "))


func spawn_projectile(prefab: PackedScene, data: Dictionary):
	var index = prefabs.find(prefab)
	assert(index >= 0, "Expected prefab to exist in prefabs list")
	spawn_projectile_id(index, data)
	
# data: {
#   name: String 
#   position: Vector2
#   direction: Vector2
# }
func spawn_projectile_id(index: int, data: Dictionary):
	assert(index >= 0 and index < prefabs.size(), "Projectile index must be within prefabs array bounds")
	if not cache_team and team:
		data.team = team.team
		data.entity_owner = team.entity_owner.get_path() if is_instance_valid(team.entity_owner) else null
		data.entity_owner_data = team.entity_owner_data
	data.time = network_manager.server_time
	data._prefab_index = index
	# Spawn immediately on our side
	if network_manager.is_server:
		# Send projectile to clients
		_spawn_projectile_clients.rpc(data)
	else:
		_spawn_projectile_clients(data)
		# Request projectile be sent to other clients
		_spawn_projectile_server.rpc_id(1, data)


@rpc("any_peer", "call_remote", "reliable")
func _spawn_projectile_server(data: Dictionary):
	for network_player in network_manager.network_players_list:
		if network_player.multiplayer_id != multiplayer.get_remote_sender_id():
			_spawn_projectile_clients.rpc_id(network_player.multiplayer_id, data)


@rpc("authority", "call_local", "reliable")
func _spawn_projectile_clients(network_data: Dictionary):
	var prefab = prefabs[network_data._prefab_index]
	var inst = prefab.instantiate() as Projectile
	var data = local_data.duplicate()
	data.merge(network_data, true)
	inst.name = prefix + str(counter)
	inst.pre_construct(data)
	world.add_child(inst)
	counter += 1
	if counter >= projectiles_limit:
		counter = 0
	on_spawn.emit()
