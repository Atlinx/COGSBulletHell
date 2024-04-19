class_name MainMenuUI
extends Control


@export var menu_manager: MenuManager
@export var network_manager: NetworkManager
@export var ip_line_edit: LineEdit
@export var port_line_edit: LineEdit
@export var host_button: Button
@export var join_button: Button
@export var cancel_button: Button


var _is_joining: bool


func _ready():
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	network_manager.game_reseted.connect(_on_game_reseted)
	network_manager.connected_to_server.connect(_on_connected_to_server)


func _on_game_reseted():
	cancel_button.visible = false
	_set_ui_disabled(false)


func _on_host_pressed():
	if network_manager.host_server(int(port_line_edit.text)):
		menu_manager.transition_to_menu("Lobby")


func _on_join_pressed():
	_is_joining = true
	cancel_button.visible = true
	_set_ui_disabled(true)
	await get_tree().process_frame
	await get_tree().process_frame
	network_manager.join_server(ip_line_edit.text, int(port_line_edit.text))


func _on_cancel_pressed():
	_is_joining = false
	network_manager.reset_game()


func _on_connected_to_server():
	if _is_joining:
		_is_joining = false
		_set_ui_disabled(false)
		menu_manager.transition_to_menu("Lobby")


func _set_ui_disabled(disabled: bool):
	join_button.disabled = disabled
	host_button.disabled = disabled
	ip_line_edit.editable = not disabled
	port_line_edit.editable = not disabled
