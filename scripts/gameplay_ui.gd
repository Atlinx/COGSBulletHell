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
	_update_info_label()


func _update_info_label():
	if multiplayer.is_server():
		info_label.text = "Hosting @ " + str(network_manager.port) + "\n"
	else:
		info_label.text = "Connected @ " + network_manager.address + ":" + str(network_manager.port) + "\n"
	info_label.text += game_manager.my_player.network_player.username + "\n"
	info_label.text += "Latency: %.4f ms\n" % network_manager.average_latency
	info_label.text += "RTT: %.4f ms\n" % network_manager.average_rtt
	info_label.text += "Time Offset: %.4f ms\n" % network_manager.server_client_time_offset


func _process(delta):
	if game_manager.is_in_game:
		_update_info_label()
