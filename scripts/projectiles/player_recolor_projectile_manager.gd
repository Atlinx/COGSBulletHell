class_name PlayerRecolorProjectileManager
extends Node


@export var player: Player  

@onready var projectile_manager: ProjectileManager = get_parent()


func _ready():
	projectile_manager.local_data.palette = player.palette.resource_path
