class_name PlayerProjectileManagerConfigurer
extends Node


@export var player: Player
@export var recolor: bool = true

@onready var projectile_manager: ProjectileManager = get_parent()


func _ready():
	if recolor:
		projectile_manager.local_data.palette = player.palette.resource_path
	if not multiplayer.is_server():
		# Ignore server projectile spawns when we're controlling the player
		# locally, since our local simulation of our own player should
		# sync with that of the server
		projectile_manager.ignore_server_spawns = player.is_controlling_player
