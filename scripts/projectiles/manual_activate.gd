## Node that receives an "activate" signal from a ManualActivateSource node.
##
## See ManualActivateSource for how the two nodes work.
class_name ManualActivate
extends Node


signal activated


@onready var projectile: Projectile = get_parent()


func _ready():
	var manual_activate_source = get_node_or_null(projectile.data.get("manual_activate_source", ""))
	if manual_activate_source is ManualActivateSource:
		manual_activate_source.activated.connect(_on_activate)


func _on_activate():
	activated.emit()
