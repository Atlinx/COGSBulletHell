class_name PlayerInput
extends MultiplayerSynchronizer


@export var direction: Vector2 = Vector2.ZERO


func _ready():
	set_process(is_multiplayer_authority())


func _process(delta):
	direction = Input.get_vector("player_left", "player_right", "player_up", "player_down").normalized()
