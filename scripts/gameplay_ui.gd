class_name GameplayUI
extends Control


@export var network_manager: NetworkManager
@export var game_manager: GameManager
@export var info_label: Label
@export var disconnect_button: Button
@export var scoreboard_entry_prefab: PackedScene
@export var scoreboard: Control
@export var show_debug_info: bool :
	get:
		return show_debug_info
	set(value):
		show_debug_info = value
		if info_label:
			info_label.visible = show_debug_info
@export var primary_ability_indicator: AbilityIndicator
@export var secondary_ability_indicator: AbilityIndicator
@export var utility_ability_indicator: AbilityIndicator
@export var special_ability_indicator: AbilityIndicator


func _ready():
	network_manager.game_reseted.connect(_on_reseted)
	game_manager.game_started.connect(_on_game_started)
	game_manager.my_player_spawned.connect(_on_my_player_spawned)
	disconnect_button.pressed.connect(_on_disconnect_pressed)
	info_label.visible = show_debug_info


func _on_disconnect_pressed():
	network_manager.reset_game()


func _on_reseted():
	visible = false
	for child in scoreboard.get_children():
		child.queue_free()


func _on_game_started():
	visible = true
	_update_info_label()
	for player in game_manager.game_players_sorted_list:
		var scoreboard_entry_inst = scoreboard_entry_prefab.instantiate() as ScoreboardEntry
		scoreboard.add_child(scoreboard_entry_inst)
		scoreboard_entry_inst.construct(player)


func _unhandled_input(event):
	if event is InputEventKey:
		if event.keycode == KEY_O and not event.pressed:
			show_debug_info = !show_debug_info


func _on_my_player_spawned(my_player: Player):
	var abilities = my_player.get_node("Abilities")
	for ability in abilities.get_children():
		if ability is PlayerAbility:
			match ability.type:
				PlayerInput.AbilityType.PRIMARY:
					primary_ability_indicator.post_construct(ability)
				PlayerInput.AbilityType.SECONDARY:
					secondary_ability_indicator.post_construct(ability)
				PlayerInput.AbilityType.UTILITY:
					utility_ability_indicator.post_construct(ability)
				PlayerInput.AbilityType.SPECIAL: 
					special_ability_indicator.post_construct(ability)
				_:
					special_ability_indicator.post_construct(null)


func _update_info_label():
	if multiplayer.is_server():
		info_label.text = "Hosting @ " + str(network_manager.port) + "\n"
	else:
		info_label.text = "Connected @ " + network_manager.address + ":" + str(network_manager.port) + "\n"
	info_label.text += network_manager.my_network_player.username + "\n"
	info_label.text += "Latency: %.4f ms\n" % network_manager.average_latency_ms
	info_label.text += "RTT: %.4f ms\n" % network_manager.average_rtt_ms
	info_label.text += "Time Offset: %.4f ms\n" % network_manager.server_time_offset_ms
	if multiplayer.is_server():
		info_label.text += "Client RTTs:\n"
		for network_player in network_manager.network_players_sorted_list:
			info_label.text += "  %s: %.4f\n" % [network_player.multiplayer_id, network_player.average_rtt_ms]


func _process(_delta):
	if game_manager.is_in_game and show_debug_info:
		_update_info_label()
