class_name BotPlayerInput
extends Node


@export var random_move_interval_range: Vector2 = Vector2(3, 5)
@export var random_aim_interval_range: Vector2 = Vector2(3, 5)
@export var random_action_interval_range: Vector2 = Vector2(0.5, 3)

var manual_player: ManualPlayer
var player_input: PlayerInput

var _random_move_timer: float
var _random_aim_timer: float
var _random_action_timer: float


func _ready():
	manual_player = get_parent() as ManualPlayer
	player_input = manual_player.player.get_node("PlayerInput")
	set_process(manual_player.is_controlling_player)


func _process(delta):
	# Moving
	if _random_move_timer >= 0:
		_random_move_timer -= delta
		if _random_move_timer < 0:
			_random_move_timer = randf_range(random_move_interval_range.x, random_move_interval_range.y)
			player_input.move_direction = Vector2.from_angle(randf() * TAU) * randf_range(0.5, 1)
	if _random_aim_timer >= 0:
		_random_aim_timer -= delta
		if _random_aim_timer < 0:
			_random_aim_timer = randf_range(random_aim_interval_range.x, random_aim_interval_range.y)
			player_input.aim_direction = Vector2.from_angle(randf() * TAU)
	if _random_action_timer >= 0:
		_random_action_timer -= delta
		if _random_action_timer < 0:
			_random_action_timer = randf_range(random_action_interval_range.x, random_action_interval_range.y)
			match randi_range(1, 4):
				1:
					player_input.is_using_primary = not player_input.is_using_primary
				2:
					player_input.is_using_secondary = not player_input.is_using_secondary
				3:
					player_input.is_using_utility = not player_input.is_using_utility
				4:
					player_input.is_using_special = not player_input.is_using_special
