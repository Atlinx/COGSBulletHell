## Node that can broadcast a "activate" signal to a projectile.
## This node should be a child of a SpawnProjectiles node.
##
## The corresponding listener node to this is the ManualActivate node.
##
## This is used in character abilities that let the player
## control the projectile with a signal even after firing.
## For example the wizard's spell bomb can be manually detonated 
## by pressing Secondary fire again.
class_name ManualActivateSource
extends Node


signal activated


func _construct_projectile(projectile_data: Dictionary):
	projectile_data.manual_activate_source = get_path()


## Activates any ManualActivateListeners connected to this node
func activate():
	activated.emit()
