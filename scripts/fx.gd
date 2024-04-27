@tool
class_name FX
extends Node2D


signal finished


@export var prefix_name_source: Node
@export var unparent_on_play: bool
@export var free_after_lifetime: bool
@export var start_delay: float
@export var lifetime: float
@export var default_animation_name: String
@export var play_on_ready: bool
## Lets FX play children FX
@export var is_chain: bool
## How much to skip ahead in the FX by
@export var preprocess: float
## Syncs the FX across clients
@export var synced: bool
@export var _play: bool :
	get:
		return _play
	set(value):
		_play = value
		if not _suppress_play:
			play()
var _suppress_play: bool

var _lifetime_timer: float
var _start_delay_timer: float
var _preprocess_tracker: float


func _ready():
	set_process(false)
	if Engine.is_editor_hint():
		return
	if play_on_ready:
		play()
	if prefix_name_source:
		name = prefix_name_source.name + name
		print("new name: based on proj: ", name)


func play():
	if not Engine.is_editor_hint() and unparent_on_play:
		reparent(World.instance, true)
	set_process(true)
	_preprocess_tracker = preprocess
	_start_delay_timer = maxf(start_delay - _preprocess_tracker, 0)
	_preprocess_tracker = maxf(_preprocess_tracker - start_delay, 0)
	if _start_delay_timer == 0:
		_process(0.1)
	if not Engine.is_editor_hint() and is_multiplayer_authority() and synced:
		_play_clients.rpc(NetworkManager.instance.server_time)


@rpc("authority", "call_remote", "reliable")
func _play_clients(start_time: float):
	preprocess = maxf(NetworkManager.instance.server_time - start_time, 0)
	play()


func _process(delta):
	if _start_delay_timer >= 0:
		_start_delay_timer -= delta
		if _start_delay_timer < 0:
			for child in get_children():
				if child is AdvancedGPUParticles2D:
					child.preprocess = _preprocess_tracker
					child.play()
				elif child is GPUParticles2D:
					child.preprocess = _preprocess_tracker
					child.emitting = true
				elif child is AudioStreamPlayer:
					child.play()
					child.seek(_preprocess_tracker)
				elif child is AudioStreamPlayer2D:
					child.play()
					child.seek(_preprocess_tracker)
				elif child is AnimationPlayer:
					child.play(default_animation_name)
					child.seek(_preprocess_tracker, true)
				elif child is SpawnProjectiles:
					if not Engine.is_editor_hint() and is_multiplayer_authority():
						child.spawn()
			_lifetime_timer = maxf(lifetime - _preprocess_tracker, 0)
			_preprocess_tracker = maxf(_preprocess_tracker - lifetime, 0)
	if _lifetime_timer >= 0:
		_lifetime_timer -= delta
		if _lifetime_timer < 0:
			if is_chain:
				for child in get_children():
					if child is FX:
						child.preprocess = _preprocess_tracker
						child.play()
						await child.finished
			if _play:
				_suppress_play = true
				_play = false
				_suppress_play = false
			finished.emit()
			if not Engine.is_editor_hint() and free_after_lifetime:
				queue_free()
