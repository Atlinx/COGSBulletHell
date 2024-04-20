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
	_destroy.rpc(global_position)


@rpc("authority", "call_local", "reliable")
func _destroy(death_position: Vector2):
	if not _is_destroyed:
		global_position = death_position
		for child in get_children():
			if child is FX:
				child.play()
		_is_destroyed = true
		destroyed.emit()
		get_parent().queue_free.call_deferred()


func _process(delta):
	_lifetime_timer += delta
	if _lifetime_timer >= lifetime:
		destroy()
