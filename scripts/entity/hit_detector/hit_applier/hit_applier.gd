class_name HitApplier
extends Node



@export var damage: int
@export var is_healing: bool

@onready var hit_detector = get_parent() as HitDetector
	

func get_damage_info() -> DamageInfo:
	var team = hit_detector.entity.get_node("Team") as Team
	var attacker = null
	var attacker_data = {}
	if team:
		if is_instance_valid(team.entity_owner):
			attacker = team.entity_owner
		attacker_data = team.entity_owner_data
	return DamageInfo.new(damage, is_healing, attacker, attacker_data)
