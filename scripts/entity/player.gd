class_name Player
extends CharacterBody2D


@export var camera: Camera2D

var network_player: NetworkManager.NetworkPlayer
var network_manager: NetworkManager
var is_controlling_player: bool :
	get:
		return network_player.multiplayer_id == multiplayer.get_unique_id()
var network_player_index: int


func construct(_network_player: NetworkManager.NetworkPlayer):
	network_player = _network_player


func _enter_tree():
	network_manager = NetworkManager.instance
	network_player_index = network_manager.network_players_sorted_list.find(network_player)
	name = "Player" + str(network_player.multiplayer_id)
	camera.enabled = is_controlling_player
