class_name Player
extends CharacterBody2D


signal died(killing_damage_info: DamageInfo)


@export var camera: Camera2D
@export var palette_swap: PaletteSwap
@export var team: Team
@export var health: Health

var game_player: GameManager.GamePlayer
var network_manager: NetworkManager
var is_controlling_player: bool :
	get:
		return game_player.network_player.multiplayer_id == multiplayer.get_unique_id()


func construct(_game_player: GameManager.GamePlayer, _team: String):
	game_player = _game_player
	palette_swap.use_palette(_game_player.palette)
	team.team = _team


func _enter_tree():
	network_manager = NetworkManager.instance
	name = "Player" + str(game_player.network_player.multiplayer_id)
	camera.enabled = is_controlling_player


func _ready():
	health.died.connect(_on_died)


func _on_died(killing_damage_info: DamageInfo):
	died.emit(killing_damage_info)
