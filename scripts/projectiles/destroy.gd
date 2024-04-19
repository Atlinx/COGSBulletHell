class_name Destroy
extends Node2D


signal destroyed


@export var use_lifetime: bool = true
@export var lifetime: float = 5

var _lifetime_timer: float
var _is_destroyed: bool


func _ready():
	set_process(use_lifetime and is_multiplayer_authority())


func destroy():
	if _is_destroyed:
		_is_destroyed = true
		destroyed.emit()
		get_parent().queue_free()


func _process(delta):
	_lifetime_timer += lifetime
	if _lifetime_timer >= lifetime:
		destroy()
