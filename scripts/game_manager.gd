class_name GameManager
extends Node


signal game_reseted
signal game_started
signal game_ticked

static var instance: GameManager

@export var tick_interval: float = 1/10.0
@export var world: Node2D
@export var network_manager: NetworkManager
@export var player_prefab: PackedScene
@export var player_spawner: MultiplayerSpawner

## [player_id: int]: Player
var players: Dictionary
var my_player: Player
var is_in_game: bool

var _tick_timer: float = 0


func _ready():
	if instance:
		queue_free()
		return
	instance = self
	network_manager.game_reseted.connect(_on_game_reseted)
	network_manager.game_started.connect(_on_game_started.unbind(1))
	player_spawner.spawned.connect(_on_player_spawned)
	player_spawner.despawned.connect(_on_player_despawned)
	player_spawner.spawn_function = _spawn_player


func _process(delta):
	if is_in_game:
		_tick_timer -= delta
		if _tick_timer <= 0:
			game_ticked.emit()
			_tick_timer = tick_interval


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		instance.queue_free()


func _on_player_spawned(player_node: Player):
	players[player_node.network_player.multiplayer_id] = player_node
	if player_node.is_controlling_player:
		my_player = player_node
	if not is_in_game and players.size() == network_manager.network_players.size():
		is_in_game = true
		game_started.emit()


func _on_player_despawned(player_node: Player):
	if player_node.network_player.multiplayer_id in players:
		players.erase(player_node.network_player.multiplayer_id)
		if player_node.is_controlling_player:
			my_player = null


func _on_game_reseted():
	for child in world.get_children():
		child.queue_free()
	players = {}
	is_in_game = false
	my_player = null
	game_reseted.emit()


func _on_game_started():
	# Only spawn players on server
	if not multiplayer.is_server():
		return
	
	for network_player in network_manager.network_players_list:
		var player_inst = player_spawner.spawn(network_player.multiplayer_id)
		_on_player_spawned.call_deferred(player_inst)


func _spawn_player(player_id: int):
	print("Spawning player with id: ", player_id)
	var player_inst = player_prefab.instantiate() as Player
	player_inst.construct(network_manager.get_player(player_id))
	return player_inst
