class_name Health
extends Node


signal healed(amount: int)
signal damaged(amount: int)
signal died


@export var health: int
@export var max_health: int

var is_dead: bool


func _ready():
	health = max_health


func change_health(amount: int):
	if amount < 0:
		damage(abs(amount))
	else:
		heal(amount)


func damage(amount: int):
	if is_dead:
		return
	
	health -= amount
	if health <= 0:
		health = 0
		is_dead = true
		died.emit()


func heal(amount: int):
	if is_dead:
		return
	
	health += amount
	if health > max_health:
		health = max_health
	healed.emit(amount)
