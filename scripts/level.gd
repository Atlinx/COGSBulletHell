extends Node2D


@export var game_manager: GameManager
@export var disable_collision_for_clients: bool = true


func _ready():
	game_manager.game_started.connect(_on_game_started)


func _on_game_started():
	if disable_collision_for_clients:
		for child in get_children():
			if child is StaticBody2D:
				var collision_shape = child.get_node("CollisionShape2D") as CollisionShape2D
				collision_shape.disabled = not multiplayer.is_server()
