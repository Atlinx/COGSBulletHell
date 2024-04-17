class_name LobbyUI
extends Control


@export var network_manager: NetworkManager
@export var ready_button: Button
@export var leave_button: Button
@export var lobby_info_label: Label
@export var lobby_users_label: Label
@export var username_line_edit: LineEdit


func _ready():
	network_manager.game_reseted.connect(_on_game_reseted)
	network_manager.network_players_updated.connect(_on_network_players_updated)
	leave_button.pressed.connect(_on_leave_pressed)
	ready_button.pressed.connect(_on_ready_pressed)
	username_line_edit.text_changed.connect(_on_username_changed)


func _on_menu_load():
	if multiplayer.is_server():
		lobby_info_label.text = "Hosting @ %s" % [network_manager.port]
	else:
		lobby_info_label.text = "Connected @ %s:%s" % [network_manager.address, network_manager.port]


func _on_game_reseted():
	ready_button.disabled = false


func _on_username_changed(new_text: String):
	var my_network_player = network_manager.my_network_player
	if new_text.length() > 3 and new_text != my_network_player.username:
		my_network_player.username = new_text
		network_manager.update_my_network_player()
	else:
		print("Username must be > 3 length")


func _on_network_players_updated():
	lobby_users_label.text = ""
	var lobby_players = network_manager.network_players.values()
	lobby_players.sort_custom(func (a: NetworkManager.NetworkPlayer, b: NetworkManager.NetworkPlayer): return a.multiplayer_id < b.multiplayer_id)
	for i in range(lobby_players.size()):
		var lobby_player: NetworkManager.NetworkPlayer = lobby_players[i]
		lobby_users_label.text += "%s %s" % [lobby_player.username, "(Readied)" if lobby_player.readied_up else ""]
		if i < lobby_players.size() - 1:
			lobby_users_label.text += "\n"


func _on_ready_pressed():
	ready_button.disabled = true
	network_manager.ready_up.rpc()


func _on_leave_pressed():
	network_manager.reset_game()
