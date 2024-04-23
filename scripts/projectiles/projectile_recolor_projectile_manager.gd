class_name ProjectileRecolorProjectileManager
extends Node


@export var projectile: Projectile  

@onready var projectile_manager: ProjectileManager = get_parent()


func _ready():
	var palette = projectile.data.get("palette")
	if palette:
		projectile_manager.local_data.palette = palette
