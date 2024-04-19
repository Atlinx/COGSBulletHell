class_name HitDetector
extends Area2D


signal detector_entered(other: HitDetector)
signal detector_exited(other: HitDetector)

enum Type {
	HIT_BOX,
	HURT_BOX
}

enum DetectMode {
	ALL,
	ENEMY,
	ALLY
}

@export var entity: Node2D
@export var type: Type
@export var detect_mode: DetectMode
@export var enabled: bool = true :
	get:
		return enabled
	set(value):
		enabled = value
		if collision_shape:
			collision_shape.disabled = not enabled

# CollisionShape2D or CollisionPolygon2D
var collision_shape
# [HitDetector]: null
var overlapping_hit_detectors: Dictionary


func _ready():
	if not is_multiplayer_authority():
		return
	enabled = enabled
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	for child in get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			collision_shape = child


func _on_area_entered(other: Area2D):
	if other is HitDetector and other.type != type:
		if detect_mode != DetectMode.ALL:
			var other_team = other.get_node_or_null("Team") as Team
			var my_team = entity.get_node_or_null("Team") as Team
			if not other_team or not my_team:
				return
			if detect_mode == DetectMode.ALLY and other_team.team != my_team.team:
				return
			elif detect_mode == DetectMode.ENEMY and other_team.team == my_team.team:
				return
			
		overlapping_hit_detectors[other] = null
		detector_entered.emit(other)
	

func _on_area_exited(other: Area2D):
	if other in overlapping_hit_detectors:
		overlapping_hit_detectors.erase(other)
		detector_exited.emit(other)
