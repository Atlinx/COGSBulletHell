class_name FX
extends Node2D


@export var unparent_on_play: bool
@export var use_lifetime: bool
@export var lifetime: float
@export var default_animation_name: String
@export var play_on_ready: bool

var _lifetime_timer: float


func _ready():
	set_process(false)
	if play_on_ready:
		play()


func play():
	if unparent_on_play:
		reparent(World.instance, true)
	for child in get_children():
		if child is AdvancedGPUParticles2D:
			child.play()
		elif child is GPUParticles2D:
			child.emitting = true
		elif child is AudioStreamPlayer:
			child.play()
		elif child is AudioStreamPlayer2D:
			child.play()
		elif child is AnimationPlayer:
			child.play(default_animation_name) 
	if use_lifetime:
		_lifetime_timer = lifetime
		set_process(true)


func _process(delta):
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		queue_free()


func _on_projectile_manager_on_spawn():
	pass # Replace with function body.
