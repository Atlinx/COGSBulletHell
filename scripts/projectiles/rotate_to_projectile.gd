extends Node


@export var projectile: Projectile
@export var offset: float

@onready var parent: Node2D = get_parent()


func _ready():
	var angle = projectile.data.get("direction", Vector2.ZERO).angle()
	parent.global_rotation = deg_to_rad(offset) + angle
