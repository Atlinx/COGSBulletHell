class_name Health
extends Node


signal damage_info_used(damage_info: DamageInfo)
signal healed(amount: int)
signal damaged(amount: int)
signal died(killing_damage: DamageInfo)


@export var health: int
@export var max_health: int

var is_dead: bool


func _ready():
	health = max_health


func use_damage_info(damage_info: DamageInfo):
	if is_dead or not multiplayer.is_server():
		return
	
	var amount = -damage_info.amount
	if damage_info.is_healing:
		amount = damage_info.amount
	
	health += amount
	health = clamp(health, 0, max_health)
	
	if damage_info.is_healing:
		healed.emit(abs(amount))
		if multiplayer.is_server():
			_sync_healed.rpc(amount)
	else:
		damaged.emit(abs(amount))
		if multiplayer.is_server():
			_sync_damaged.rpc(amount)
	damage_info_used.emit(damage_info)
	
	if health <= 0:
		health = 0
		is_dead = true
		died.emit(damage_info)


@rpc("authority", "call_remote", "reliable")
func _sync_damaged(amount: int):
	health -= max(amount, 0)
	damaged.emit(amount)
	is_dead = health == 0


@rpc("authority", "call_remote", "reliable")
func _sync_healed(amount: int):
	health += min(amount, max_health)
	healed.emit()
