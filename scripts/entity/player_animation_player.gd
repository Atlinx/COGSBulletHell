extends AnimationPlayer


@export var idle_animation: String = "idle"
@export var walk_animation: String = "walk"
@export var player_move: PlayerMove


func _ready():
	player_move.is_moving_changed.connect(_is_moving_changed)
	_is_moving_changed(player_move.is_moving)


func _is_moving_changed(is_moving: bool):
	if is_moving and current_animation != walk_animation:
		play(walk_animation)
	elif current_animation != idle_animation:
		play(idle_animation)
