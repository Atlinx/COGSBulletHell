## A script that configures a player to be manually
## controlled, as well as binding a camera
## to the player.
class_name ManualPlayer
extends Node2D


@export var camera: Camera2D

var player: Player
var game_player: GameManager.GamePlayer
var is_controlling_player: bool


func pre_construct(_game_player: GameManager.GamePlayer, _team: String):
	game_player = _game_player
	player = get_parent()
	player.pre_construct(game_player.palette, _team)
	player.name = "Player" + str(game_player.network_player_index)


func _enter_tree():
	is_controlling_player = game_player.network_player.multiplayer_id == multiplayer.get_unique_id()
	player.is_controlling_player = is_controlling_player


func _ready():
	camera.enabled = player.is_controlling_player
