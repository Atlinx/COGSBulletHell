class_name OverlayFX
extends Node


@export var visuals: Node2D
@export var ease: Tween.EaseType
@export var transition: Tween.TransitionType
@export var duration: float
@export var one_to_zero: bool = true


func _ready():
	visuals.material = visuals.material.duplicate()
	_set_overlay(0.0)


func play():
	var tween = create_tween()
	tween.set_ease(ease).set_trans(transition)
	if one_to_zero:
		tween.tween_method(_set_overlay, 1.0, 0.0, duration)
	else:
		tween.tween_method(_set_overlay, 0.0, 1.0, duration)


func _set_overlay(amount: float):
	var mat = visuals.material as ShaderMaterial
	mat.set_shader_parameter("overlay_amount", amount)
