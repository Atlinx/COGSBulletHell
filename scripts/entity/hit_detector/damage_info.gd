class_name DamageInfo
extends RefCounted


var amount: int
var is_healing: bool
var attacker: Node2D
var attacker_data: Dictionary


func _init(_amount: int, _is_healing: bool, _attacker: Node2D, _attacker_data: Dictionary):
	amount = _amount
	is_healing = _is_healing
	attacker = _attacker
	attacker_data = _attacker_data
