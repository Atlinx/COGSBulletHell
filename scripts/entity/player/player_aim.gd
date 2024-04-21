## Controls player aiming
class_name PlayerAim
extends Node


@export var visuals: Node2D
@export var input: PlayerInput
@export var fire_rotation: Node2D
@export var muzzle: Node2D
@export var lerp_factor: float = 20

@onready var player:  = get_parent()
var network_manager: NetworkManager
var _is_lerping: bool


func _ready():
	network_manager = NetworkManager.instance
	_is_lerping = not player.is_controlling_player
	if network_manager.is_player_server and not player.is_controlling_player:
		fire_rotation.reparent.call_deferred(visuals, true)


func _process(delta):
	if _is_lerping:
		fire_rotation.global_rotation = lerp_angle(fire_rotation.global_rotation, input.aim_direction.angle(), clampf(lerp_factor * delta, 0.0, 1.0))
	else:
		fire_rotation.global_rotation = input.aim_direction.angle()
