class_name Player
extends CharacterBody2D


@export var speed: float = 100;
@export var player_input: PlayerInput
@export var camera: Camera2D

var network_player: NetworkManager.NetworkPlayer


func construct(_network_player: NetworkManager.NetworkPlayer):
	network_player = _network_player
	$PlayerInput.set_multiplayer_authority(network_player.multiplayer_id)


func _ready():
	name = "Player" + str(network_player.multiplayer_id)
	camera.enabled = network_player.multiplayer_id == multiplayer.get_unique_id()


func _physics_process(delta):
	velocity = player_input.direction * speed

	move_and_slide()
