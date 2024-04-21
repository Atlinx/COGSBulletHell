class_name ForwardProjectileMove
extends Node


@onready var projectile = get_parent() as Projectile
@export var speed: float
@export var direction: Vector2

var network_manager: NetworkManager


func _ready():
	network_manager = NetworkManager.instance
	speed = projectile.data.get("speed", speed)
	direction = projectile.data.get("direction", direction)
	projectile.global_position = projectile.data.get("position", Vector2.ZERO)
	var server_time: float = projectile.data.get("time")
	var dist_already_travelled = direction * speed * (network_manager.server_time - server_time)
	projectile.global_position += dist_already_travelled


func _process(delta):
	projectile.global_position += direction * speed * delta
