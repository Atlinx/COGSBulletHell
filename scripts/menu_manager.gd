class_name MenuManager
extends Control


@export var network_manager: NetworkManager


func _ready():
	network_manager.game_started.connect(_on_game_started.unbind(1))
	network_manager.game_reseted.connect(_on_game_reseted)


func _on_game_reseted():
	visible = true
	transition_to_menu("MainMenu")


func _on_game_started():
	visible = false


func transition_to_menu(menu_name: String):
	for child: Control in get_children():
		if child.name == "BG":
			continue
		var should_be_visible = child.name == menu_name
		if child.visible and not should_be_visible and child.has_method("_on_menu_unload"):
			child._on_menu_unload()
		elif not child.visible and should_be_visible and child.has_method("_on_menu_load"):
			child._on_menu_load()
		child.visible = should_be_visible
