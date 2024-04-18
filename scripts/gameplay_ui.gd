class_name GameplayUI
extends Control


@export var network_manager: NetworkManager
@export var game_manager: GameManager
@export var info_label: Label
@export var disconnect_button: Button


func _ready():
	network_manager.game_reseted.connect(_on_reseted)
	game_manager.game_started.connect(_on_game_started)
	disconnect_button.pressed.connect(_on_disconnect_pressed)


func _on_disconnect_pressed():
	network_manager.reset_game()


func _on_reseted():
	visible = false


func _on_game_started():
	visible = true
	if multiplayer.is_server():
		info_label.text = "Hosting @ " + str(network_manager.port) + "\n"
	else:
		info_label.text = "Connected @ " + network_manager.address + ":" + str(network_manager.port) + "\n"
	info_label.text += game_manager.my_player.network_player.username + "\n"
