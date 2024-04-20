extends Node


@export var projectile: Projectile
@export var offset: float

@onready var parent: Node2D = get_parent()


func _ready():
	projectile.constructed.connect(_on_constructed)


func _on_constructed(data: Dictionary):
	var angle = data.get("direction", Vector2.ZERO).angle()
	parent.global_rotation = deg_to_rad(offset) + angle
