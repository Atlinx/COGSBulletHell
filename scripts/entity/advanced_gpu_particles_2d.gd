class_name AdvancedGPUParticles2D
extends GPUParticles2D

## If enabled, the particle system can repeated be
## played even while particles from previous
## "plays" still exist on the screen. 
@export var repeat_oneshot: bool
## Number of particle copies to preload
@export var repeat_oneshot_preload: int = 0

var _free_copies: Dictionary = {}


func _ready():
	if repeat_oneshot:
		one_shot = true
		emitting = false
		_free_copies[self] = null
		self.finished.connect(_on_finished.bind(self))
		_init_copies.call_deferred()


func _init_copies():
	if repeat_oneshot_preload > 0:
		for i in range(repeat_oneshot_preload):
			_create_copy()


func play():
	if repeat_oneshot:
		if _free_copies.size() == 0:
			_create_copy()
		_play_copy(_free_copies.keys()[0])
	else:
		emitting = true


func _create_copy():
	var copy = duplicate() as AdvancedGPUParticles2D
	copy.repeat_oneshot = false
	get_parent().add_child(copy)
	copy.finished.connect(_on_finished.bind(copy))
	_free_copies[copy] = null


func _play_copy(copy: AdvancedGPUParticles2D):
	_free_copies.erase(copy)
	copy.restart()


func _on_finished(copy: AdvancedGPUParticles2D):
	_free_copies[copy] = null
