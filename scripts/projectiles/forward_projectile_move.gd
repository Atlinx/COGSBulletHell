class_name ForwardProjectileMove
extends Node


@onready var projectile = get_parent() as Projectile
@export var speed: float
@export var direction: Vector2

var network_manager: NetworkManager


func _ready():
	projectile.constructed.connect(_on_constructed)
	network_manager = NetworkManager.instance


func _on_constructed(data: Dictionary):
	speed = data.get("speed", speed)
	direction = data.get("direction", direction)
	projectile.global_position = data.get("position", Vector2.ZERO)
	var server_time: float = data.get("time")
	var dist_already_travelled = direction * speed * (network_manager.server_time - server_time)
	projectile.global_position += dist_already_travelled


func _process(delta):
	projectile.global_position += direction * speed * delta
