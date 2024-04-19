class_name ProjectileManager
extends Node


@export var prefix: String
@export var use_parent_team: bool = true
@export var prefabs: Array[PackedScene]

var network_manager: NetworkManager
var world: World
var counter: int

func _ready():
	world = World.instance
	network_manager = NetworkManager.instance


# data: {
#   name: String 
#   position: Vector2
#   direction: Vector2
# }
func spawn_projectile(prefab: PackedScene, data: Dictionary):
	var index = prefabs.find(prefab)
	assert(index >= 0, "Expected prefab to exist in prefabs list")
	if use_parent_team:
		var parent_team = get_parent().get_node_or_null("Team") as Team
		if parent_team and not "team" in data:
			data.team = parent_team.team
		if not "entity_owner" in data:
			data.entity_owner = get_parent().get_path()
			print('set owner to ', data.entity_owner)
	data.time = network_manager.server_time
	data._prefab_index = index
	# Spawn immediately on our side
	print("spawning immediately time: ", network_manager.server_time)
	_spawn_projectile_clients(data)
	if network_manager.is_server:
		# Send projectile to clients
		_spawn_projectile_clients.rpc(data)
	else:
		# Request projectile be sent to other clients
		_spawn_projectile_server.rpc_id(1, data)


@rpc("any_peer", "call_local", "reliable")
func _spawn_projectile_server(data: Dictionary):
	for network_player in network_manager.network_players_list:
		if network_player.multiplayer_id != multiplayer.get_remote_sender_id():
			_spawn_projectile_clients.rpc_id(network_player.multiplayer_id, data)


@rpc("authority", "call_local", "reliable")
func _spawn_projectile_clients(data: Dictionary):
	print("  spawning proj on client: ", data, " time: ", network_manager.server_time)
	var prefab = prefabs[data._prefab_index]
	var inst = prefab.instantiate() as Projectile
	inst.name = prefix + str(counter)
	world.add_child(inst)
	inst.construct(data)
	counter += 1
