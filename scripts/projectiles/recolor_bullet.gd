@tool
extends Node


@export var color: Color :
	get:
		return _color
	set(value):
		_color = value
		if Engine.is_editor_hint():
			_on_constructed({ "color": _color })
var _color: Color
@export var visual: Node2D
@export var glow: Node2D
@export var particles: GPUParticles2D

@onready var projectile: Projectile = get_parent()


func _ready():
	if Engine.is_editor_hint():
		_on_constructed({ "color": color })
		return
	projectile.constructed.connect(_on_constructed)
	visual.material = visual.material.duplicate()


func _on_constructed(data: Dictionary):
	_color = data.get("color", _color)
	(visual.material as ShaderMaterial).set_shader_parameter("replace_0", _color)
	glow.self_modulate = _color
	glow.self_modulate.a = 0.25
	particles.self_modulate = _color
