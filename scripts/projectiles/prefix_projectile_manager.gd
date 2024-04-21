class_name PrefixProjectileManager
extends Node


@export var base_node: Node
@export var prefix: String

@onready var projectile_manager: ProjectileManager = get_parent()


func _ready():
	projectile_manager.prefix = base_node.name + prefix


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
