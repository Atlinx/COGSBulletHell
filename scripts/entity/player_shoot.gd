class_name PlayerShoot
extends Node


signal on_shoot


@export var projectile_prefab: PackedScene
@export var projectile_manager: ProjectileManager
@export var input: PlayerInput

@onready var player: Player = get_parent()


func _ready():
	projectile_manager.prefix = "Player" + str(player.network_player_index) + "Proj"
	input.on_shoot.connect(_on_shoot)


func _on_shoot():
	projectile_manager.spawn_projectile(projectile_prefab, {
		"position": player.global_position,
		"direction": input.aim_direction
	})
	on_shoot.emit()
