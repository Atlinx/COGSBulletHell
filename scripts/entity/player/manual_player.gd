## A script that configures a player to be manually
## controlled, as well as binding a camera
## to the player.
class_name ManualPlayer
extends Node2D


static var global_camera_zoom: float = 0.5 :
	set(value):
		global_camera_zoom = clampf(value, MIN_CAMERA_ZOOM, MAX_CAMERA_ZOOM)
const MIN_CAMERA_ZOOM: float = 0.25
const MAX_CAMERA_ZOOM: float = 2


@export var camera: Camera2D
@export var username_label: Label
@export var player_ui: Control

var player: Player
var game_player: GameManager.GamePlayer
var is_controlling_player: bool
var camera_zoom: float :
	get:
		return global_camera_zoom
	set(value):
		global_camera_zoom = value
		if camera:
			camera.zoom = Vector2.ONE * global_camera_zoom


func pre_construct(_game_player: GameManager.GamePlayer, _team: String):
	game_player = _game_player
	player = get_parent()
	player.pre_construct(game_player.palette, _team)
	player.name = "Player" + str(game_player.network_player_index)
	player.team.entity_owner_data.player_id = _game_player.network_player.multiplayer_id
	username_label.text = game_player.network_player.username
	camera.zoom = Vector2.ONE * global_camera_zoom


func _enter_tree():
	is_controlling_player = game_player.network_player.multiplayer_id == multiplayer.get_unique_id()
	player.is_controlling_player = is_controlling_player


func _ready():
	camera.enabled = player.is_controlling_player
	player_ui.reparent(player.visuals_container)
