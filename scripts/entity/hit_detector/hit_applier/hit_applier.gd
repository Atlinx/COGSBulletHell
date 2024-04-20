class_name HitApplier
extends Node



@export var damage: int
@export var is_healing: bool

@onready var hit_detector = get_parent() as HitDetector
	

func get_damage_info() -> DamageInfo:
	var team = hit_detector.entity.get_node("Team") as Team
	var attacker = null
	if team:
		attacker = team.entity_owner
	return DamageInfo.new(damage, is_healing, attacker)
