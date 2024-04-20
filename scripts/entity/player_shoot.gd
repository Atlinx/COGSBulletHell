class_name PlayerShoot
extends Node


signal on_shoot


@export var projectile_prefab: PackedScene
@export var projectile_manager: ProjectileManager
@export var visuals: Node2D
@export var input: PlayerInput
@export var fire_rotation: Node2D
@export var muzzle: Node2D
@export var lerp_factor: float = 20

@onready var player: Player = get_parent()
var network_manager: NetworkManager
var _is_lerping: bool


func _ready():
	network_manager = NetworkManager.instance
	projectile_manager.prefix = "Player" + str(player.game_player.network_player_index) + "Proj"
	input.on_shoot.connect(_on_shoot)
	_is_lerping = not player.is_controlling_player
	if network_manager.is_player_server and not player.is_controlling_player:
		print("reparent visuals")
		fire_rotation.reparent.call_deferred(visuals, true)


func _process(delta):
	if _is_lerping:
		fire_rotation.global_rotation = lerp_angle(fire_rotation.global_rotation, input.aim_direction.angle(), clampf(lerp_factor * delta, 0.0, 1.0))
	else:
		fire_rotation.global_rotation = input.aim_direction.angle()


func _on_shoot():
	projectile_manager.spawn_projectile(projectile_prefab, {
		"position": muzzle.global_position,
		"direction": input.aim_direction,
		"color": player.game_player.palette.color_1
	})
	on_shoot.emit()
