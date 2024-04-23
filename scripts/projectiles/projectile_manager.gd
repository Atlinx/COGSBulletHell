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
## Lets the projectile manager ignore server spawns
## ProjectileManagers controlled by a client should
## have this flag set to true to avoid
## creating two projectiles from a single spawn.
@export var ignore_server_spawns: bool


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
	if network_manager.is_server:
		# If we're the server, send projectile to clients
		_spawn_projectile_on_clients.rpc(data)
	else:
		# Only spawn projectile locally
		# The server should eventually spawn the same projectiles if 
		# the server simulation agrees with the client simulation
		_spawn_projectile_locally(data)


@rpc("authority", "call_local", "reliable")
func _spawn_projectile_on_clients(network_data: Dictionary):
	if ignore_server_spawns:
		return
	_spawn_projectile_locally(network_data)


func _spawn_projectile_locally(network_data: Dictionary):
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
