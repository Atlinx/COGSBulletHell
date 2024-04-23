## Spawns projectiles with a customizable pattern
##
## Children of this node can edit the spawned projectiles by implementing
## a `_construct_projectile(data: Dictionary)` method, which gets 
## automatically called whenever a new projectile is made.
## The new projectile's data dictionary is passed into the method,
## allowing modification of the new projectile's data.
@tool
class_name SpawnProjectiles
extends Node


signal projectiles_spawned
signal round_spawned


@export var projectile_manager: ProjectileManager
@export var muzzle: Node2D
# Distance in front of muzzle used to spawn projectiles
@export var muzzle_offset: float
@export var prefab_index: int
@export var amount: int
@export var is_radial: bool :
	get:
		return is_radial
	set(value):
		is_radial = value
		if Engine.is_editor_hint():
			notify_property_list_changed()
@export var arc: float
@export var angle_offset: float = 0
@export var rounds: int = 1
@export var round_interval: float = 1
@export var round_angle_offset: float = 0
@export var local_data: Dictionary

var network_manager: NetworkManager


func _ready():
	network_manager = NetworkManager.instance


# Used for spawning projectiles in abilities
func _send_ability_data(data: Dictionary):
	data.muzzle_position = muzzle.global_position
	data.muzzle_rotation = muzzle.global_rotation


# Used for spawning projectiles in abilities
func _receive_ability_data(data: Dictionary):
	# TODO NOW: Calculate network latency of server to each individual client
	#
	# Calcuating latency on server using pings to clients should be safe.
	# - Use an packet acknowledgement system
	# - Every ping packet has an ID, and we receive acknowledgements back from client
	# - If ping packet remains unacknowledged for a long time (10s), we kick the client
	# - If ping packet is acknowledge out of order, we kick the client
	#   - This is b/c we know we're using TCP which should be reliable
	#   - Any out of order acknowledgement must mean tampering with the ping code. 
	# - We calculate latency as (ping packet receive time - ping packet sent time) (all on server side)
	#
	# Then we can use this latency within this check and other checks like this to verify
	# that the data we're receiving from clients is within acceptable bounds.
	#
	# We can then create a max server movement factor on PlayerMove that's dependent our latency to
	# a client. This would limit arbitrary movement (speed hacks) for clients on the server.
	if (data.muzzle_position as Vector2).distance_squared_to(muzzle.global_position) < max(3 * network_manager.average_latency_ms, 32):
		return
	muzzle.global_position = data.muzzle_position
	muzzle.global_rotation = data.muzzle_rotation


func spawn(_prefab_index: int = prefab_index):
	var angle_per_bullet: float
	if is_radial:
		angle_per_bullet = TAU / (amount + 1)
	else:
		angle_per_bullet = arc / amount
	for r in range(rounds):
		for i in range(amount):
			var angle: float
			if is_radial:
				angle = angle_per_bullet * i + angle_offset + r * round_angle_offset
			else:
				angle = angle_per_bullet * i - arc / 2 + angle_offset
			var direction = Vector2.from_angle(muzzle.global_rotation + angle)
			var data = {
				"position": muzzle.global_position + direction * muzzle_offset,
				"direction": direction
			}
			data.merge(local_data)
			for child in get_children():
				if child.has_method("_construct_projectile"):
					child._construct_projectile(data)
			projectile_manager.spawn_projectile_id(_prefab_index, data)
		round_spawned.emit()
		await get_tree().create_timer(round_interval).timeout
	projectiles_spawned.emit()


func _validate_property(property):
	if property.name == "arc" and is_radial:
		property.usage = PROPERTY_USAGE_NO_EDITOR
