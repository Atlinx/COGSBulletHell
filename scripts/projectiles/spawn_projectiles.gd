@tool
class_name SpawnProjectiles
extends Node


signal projectiles_spawned


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


func spawn(_prefab_index: int = prefab_index):
	var angle_per_bullet: float
	if is_radial:
		angle_per_bullet = 360 / (amount + 1)
	else:
		angle_per_bullet = arc / amount
	print("shoot amount: ", amount)
	for i in range(amount):
		print("  shooting: ", i)
		var angle: float
		if is_radial:
			angle = angle_per_bullet * i + angle_offset
		else:
			angle = angle_per_bullet * i - arc / 2 + angle_offset
		var direction = Vector2.from_angle(muzzle.global_rotation + angle)
		projectile_manager.spawn_projectile_id(_prefab_index, {
			"position": muzzle.global_position + direction * muzzle_offset,
			"direction": direction
		})
		projectiles_spawned.emit()


func _validate_property(property):
	if property.name == "arc" and is_radial:
		property.usage = PROPERTY_USAGE_NO_EDITOR
