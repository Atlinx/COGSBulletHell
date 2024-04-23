## Represents an ability for
## a player character.
@tool
class_name PlayerAbility
extends Node2D


## Called when the ability button is pressed
signal used_pressed
## Called when the ability button is released
signal used_released
## Called when the cooldown is over
signal cooldown_over


@export var player_input: PlayerInput
@export var type: PlayerInput.AbilityType :
	get:
		return type
	set(value):
		type = value
		if Engine.is_editor_hint():
			name = (PlayerInput.AbilityType.find_key(type) as String).to_pascal_case()
@export var cooldown: float
## Whether the ability button is pressed down
var is_used_pressed: bool :
	get:
		return player_input.is_ability_used(type)


var on_cooldown: bool :
	get: 
		return _cooldown_timer >= 0
var _cooldown_timer: float = -1


func _ready():
	if Engine.is_editor_hint():
		set_process(false)
		return
	player_input.on_ability_used.connect(_on_ability_used)


func _on_ability_used(ability_type: PlayerInput.AbilityType, pressed: bool):
	if ability_type == type:
		if pressed:
			used_pressed.emit()
		else:
			used_released.emit()


## Stars the cooldown for this ability
func start_cooldown():
	_cooldown_timer = cooldown
	set_process(true)


func _process(delta):
	if _cooldown_timer >= 0:
		_cooldown_timer -= delta
		if _cooldown_timer < 0:
			cooldown_over.emit()
