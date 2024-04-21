class_name UniqueMaterial
extends Node


func _ready():
	if get_parent() is CanvasItem:
		get_parent().material = get_parent().material.duplicate()
