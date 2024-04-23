@tool
class_name PlayerAbility
extends Node2D


## Called when the ability is used
signal used
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
@export var use_on_pressed: bool = true
@export var use_while_pressed: bool = true


var on_cooldown: bool :
	get: 
		return _cooldown_timer >= 0
var _cooldown_timer: float = -1


func _ready():
	if Engine.is_editor_hint():
		set_process(false)
		return
	player_input.on_ability_used.connect(_on_ability_used)


func _on_ability_used(ability_type: PlayerInput.AbilityType):
	if ability_type == type and use_on_pressed:
		use()


func use():
	if on_cooldown:
		return
	_cooldown_timer = cooldown
	set_process(true)
	used.emit()
	for child in get_children():
		if child is SpawnProjectiles:
			child.spawn()


func _process(delta):
	if use_while_pressed and player_input.is_ability_used(type):
		use()
	if _cooldown_timer >= 0:
		_cooldown_timer -= delta
		if _cooldown_timer < 0:
			cooldown_over.emit()
