class_name DamageInfo
extends RefCounted


var amount: int
var is_healing: bool
var attacker: Node2D


func _init(_amount: int, _is_healing: bool, _attacker: Node2D):
	amount = _amount
	is_healing = _is_healing
	attacker = _attacker
