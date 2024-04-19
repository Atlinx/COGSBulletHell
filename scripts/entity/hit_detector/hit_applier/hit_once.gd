class_name HitOnce
extends HitApplier


# [HitDetector]: null
var already_hit: Dictionary


func _ready():
	hit_detector.detector_entered.connect(_on_detector_entered)


func _on_detector_entered(other_detector: HitDetector):
	if not other_detector in already_hit:
		already_hit[other_detector] = null
		var health = other_detector.entity.get_node_or_null("Health") as Health
		if health:
			if is_healing:
				health.heal(damage)
			else:
				health.damage(damage)
