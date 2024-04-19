class_name HitApplier
extends Node



@export var damage: int
@export var is_healing: bool

@onready var hit_detector = get_parent() as HitDetector
	
