class_name Projectile
extends Node2D


signal constructed(data: Dictionary)

var data: Dictionary


func construct(_data: Dictionary):
	data = _data
	var team = get_node("Team") as Team
	team.team = data.team
	team.entity_owner = get_node_or_null(data.entity_owner)
	constructed.emit(_data)
	print("  construct proj time: ", NetworkManager.instance.server_time)
