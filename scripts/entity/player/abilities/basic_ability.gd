class_name BasicAbility
extends Node


## Called when the ability is used during cooldown
signal cooldown_used
## Called when ability is used
signal used

@export var use_on_pressed: bool = true
@export var use_on_released: bool = true
@export var use_while_pressed: bool = true


@onready var ability: PlayerAbility = get_parent()


func _ready():
	if use_on_pressed:
		ability.used_pressed.connect(use)
	if use_on_released:
		ability.used_released.connect(use)
	set_process(use_while_pressed)


func use():
	if ability.on_cooldown:
		cooldown_used.emit()
		return
	ability.start_cooldown()
	for child in get_children():
		if child is SpawnProjectiles:
			child.spawn()
	used.emit()


func _process(delta):
	if ability.is_used_pressed:
		use()
