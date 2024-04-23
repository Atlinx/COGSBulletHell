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
@export var spawn_delay: float 
@export var spawn_on_ready: bool
@export var local_data: Dictionary


func _ready():
	if spawn_on_ready and is_multiplayer_authority():
		spawn.call_deferred()


func spawn(_prefab_index: int = prefab_index):
	if spawn_delay > 0:
		await get_tree().create_timer(spawn_delay).timeout
	var angle_per_bullet: float
	if is_radial:
		angle_per_bullet = TAU / amount
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
