class_name TeleportAbility
extends Node


@export var teleport_marker: Node2D
@export var select_range: float = 500
@export var select_duration: float = 5
@export var select_curve: Curve
@export var player: Node2D
@export var player_input: PlayerInput
@export var player_move: PlayerMove

@onready var player_ability: PlayerAbility = get_parent()
var _select_timer: float


func _ready():
	teleport_marker.visible = false
	player_ability.used_pressed.connect(_on_used_pressed)
	player_ability.used_released.connect(_on_used_released)
	set_process(false)


func _on_used_pressed():
	if player_ability.on_cooldown:
		return
	teleport_marker.global_position = player.global_position
	teleport_marker.visible = true
	_select_timer = 0
	set_process(true)


func _on_used_released():
	if player_ability.on_cooldown:
		return
	teleport_marker.visible = false
	player_ability.start_cooldown()
	set_process(false)


func _process(delta):
	_select_timer += delta
	var amount = clampf(_select_timer / select_duration, 0, 1)
	var distance = select_curve.sample(amount) * select_range
	teleport_marker.global_position = player.global_position + player_input.aim_direction * distance
	if _select_timer >= select_duration:
		_on_used_released()
