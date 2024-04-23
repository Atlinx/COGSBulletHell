class_name Projectile
extends Node2D


var data: Dictionary


func pre_construct(_data: Dictionary):
	data = _data


func _enter_tree():
	var team = get_node("Team") as Team
	team.team = data.team
	team.entity_owner = get_node_or_null(data.entity_owner)
	team.entity_owner_data = data.entity_owner_data
