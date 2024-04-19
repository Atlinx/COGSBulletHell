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
	if is_dead or not multiplayer.is_server():
		return
	
	health -= max(amount, 0)
	damaged.emit(amount)
	
	if multiplayer.is_server():
		_sync_damaged.rpc(amount)
	
	if health <= 0:
		health = 0
		is_dead = true
		died.emit()


func heal(amount: int):
	if is_dead or not multiplayer.is_server():
		return
	
	health += min(amount, max_health)
	healed.emit(amount)
	
	if multiplayer.is_server():
		_sync_healed.rpc(amount)


@rpc("authority", "call_remote", "reliable")
func _sync_damaged(amount: int):
	health -= max(amount, 0)
	damaged.emit(amount)
	is_dead = health == 0


@rpc("authority", "call_remote", "reliable")
func _sync_healed(amount: int):
	health += min(amount, max_health)
	healed.emit()
