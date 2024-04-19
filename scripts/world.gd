class_name World
extends Node2D


static var instance: World


func _enter_tree():
	if instance:
		queue_free()
		return
	instance = self


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		if instance == self:
			instance = null
