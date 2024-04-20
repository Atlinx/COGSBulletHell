class_name GameplayUI
extends Control


@export var network_manager: NetworkManager
@export var game_manager: GameManager
@export var info_label: Label
@export var disconnect_button: Button
@export var scoreboard_entry_prefab: PackedScene
@export var scoreboard: Control


func _ready():
	network_manager.game_reseted.connect(_on_reseted)
	game_manager.game_started.connect(_on_game_started)
	disconnect_button.pressed.connect(_on_disconnect_pressed)


func _on_disconnect_pressed():
	network_manager.reset_game()


func _on_reseted():
	visible = false
	for child in scoreboard.get_children():
		child.queue_free()


func _on_game_started():
	visible = true
	_update_info_label()
	for player in game_manager.game_players_list:
		var scoreboard_entry_inst = scoreboard_entry_prefab.instantiate() as ScoreboardEntry
		scoreboard.add_child(scoreboard_entry_inst)
		scoreboard_entry_inst.construct(player)
	


func _update_info_label():
	if multiplayer.is_server():
		info_label.text = "Hosting @ " + str(network_manager.port) + "\n"
	else:
		info_label.text = "Connected @ " + network_manager.address + ":" + str(network_manager.port) + "\n"
	info_label.text += network_manager.my_network_player.username + "\n"
	info_label.text += "Latency: %.4f ms\n" % network_manager.average_latency_ms
	info_label.text += "RTT: %.4f ms\n" % network_manager.average_rtt_ms
	info_label.text += "Time Offset: %.4f ms\n" % network_manager.server_time_offset_ms


func _process(delta):
	if game_manager.is_in_game:
		_update_info_label()
