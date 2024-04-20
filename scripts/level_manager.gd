class_name LevelManager
extends Node2D


@export var level_prefab: PackedScene
@export var game_manager: GameManager
@export var disable_collision_for_clients: bool = true

var level_inst: Node2D
var spawnpoints: Array[Node2D]


func _enter_tree():
	for child in get_children():
		child.queue_free()


func _ready():
	game_manager.game_reseted.connect(_on_game_reseted)


func load_level():
	level_inst = level_prefab.instantiate()
	add_child(level_inst)
	if disable_collision_for_clients:
		for child in get_children():
			if child is StaticBody2D:
				var collision_shape = child.get_node("CollisionShape2D") as CollisionShape2D
				collision_shape.disabled = not multiplayer.is_server()
	spawnpoints = []
	spawnpoints.assign(get_tree().get_nodes_in_group("Spawnpoint"))
	print("loaded level with spawnpoints: ", spawnpoints)


func _on_game_reseted():
	if level_inst:
		level_inst.queue_free()
	level_inst = null
