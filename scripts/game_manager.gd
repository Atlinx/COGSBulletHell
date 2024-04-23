class_name GameManager
extends Node


signal game_reseted
signal game_started
signal game_ticked
signal my_player_spawned(my_player: Player)


class GamePlayer extends RefCounted:
	signal score_updated(new_amount: int)
	
	var network_player_index: int
	var network_player: NetworkManager.NetworkPlayer
	var loaded_level: bool
	var player_inst: Player
	var palette: ColorPalette
	var score: int :
		get:
			return score
		set(value):
			score = value
			score_updated.emit(score)
	var multiplayer_id: int :
		get:
			return network_player.multiplayer_id
	
	func _init(_network_player: NetworkManager.NetworkPlayer, _network_player_index: int, _palette: ColorPalette):
		network_player = _network_player
		palette = _palette
		network_player_index = _network_player_index


static var instance: GameManager

@export var tick_interval: float = 1/10.0
@export var spawn_interval: float = 2
@export var world: Node2D
@export var network_manager: NetworkManager
@export var level_manager: LevelManager
@export var player_prefab: PackedScene
@export var manual_player_prefab: PackedScene
@export var color_palettes: Array[ColorPalette]

## [player_id: int]: GamePlayer
var game_players: Dictionary
var game_players_list: Array[GamePlayer] :
	get:
		var list: Array[GamePlayer] = []
		list.assign(game_players.values())
		return list
var game_players_sorted_list: Array[GamePlayer] :
	get:
		var _game_players_list = game_players_list
		_game_players_list.sort_custom(func (a: GamePlayer, b: GamePlayer): return a.multiplayer_id < b.multiplayer_id)
		return _game_players_list
var my_player: Player
var is_in_game: bool

var _tick_timer: float = 0
var _game_count: int = 0


func _ready():
	if instance:
		queue_free()
		return
	instance = self
	network_manager.game_reseted.connect(_on_game_reseted)
	network_manager.game_started.connect(_on_game_started.unbind(1))


func _process(delta):
	if is_in_game:
		_tick_timer -= delta
		if _tick_timer <= 0:
			game_ticked.emit()
			_tick_timer = tick_interval


func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		instance.queue_free()


func get_player(id: int) -> GamePlayer:
	return game_players.get(id)


func _on_game_reseted():
	for child in world.get_children():
		child.queue_free()
	_game_count += 1
	game_players = {}
	is_in_game = false
	my_player = null
	game_reseted.emit()


func _on_game_started():
	var sorted_network_players = network_manager.network_players_sorted_list
	for player_id in network_manager.network_players:
		var network_player = network_manager.get_player(player_id)
		var network_player_index = sorted_network_players.find(network_player)
		game_players[player_id] = GamePlayer.new(network_player, network_player_index, color_palettes[network_player_index])
	level_manager.load_level()
	if network_manager.is_server:
		_load_level_finished(1)
	else:
		_client_load_level_finished.rpc_id(1)


## Notifies server that client finished loading level
@rpc("any_peer", "call_remote", "reliable")
func _client_load_level_finished():
	_load_level_finished(multiplayer.get_remote_sender_id())


func _load_level_finished(id: int):
	get_player(id).loaded_level = true
	var players_loaded_level: int = 0
	for player in game_players_list:
		if player.loaded_level:
			players_loaded_level += 1
	if players_loaded_level == network_manager.network_players.size():
		_spawn_players()


func _spawn_players():
	# Only spawn game_players on server
	for network_player in network_manager.network_players_list:
		_spawn_player_randomly(network_player.multiplayer_id)


@rpc("authority", "call_local", "reliable")
func _spawn_player(player_id: int, location: int):
	var game_player = get_player(player_id)
	var player_inst = player_prefab.instantiate() as Player
	var manual_player = manual_player_prefab.instantiate() as ManualPlayer
	player_inst.add_child(manual_player)
	manual_player.pre_construct(game_player, "Player" + str(game_player.network_player_index))
	player_inst.global_position = level_manager.spawnpoints[location].global_position
	if network_manager.is_server:
		player_inst.died.connect(_on_player_died.bind(player_inst))
	world.add_child(player_inst)
	game_player.player_inst = player_inst
	if player_inst.is_controlling_player:
		my_player = player_inst
	var loaded_players: int = 0
	for player in game_players_list:
		if player.player_inst != null:
			loaded_players += 1
	if not is_in_game and loaded_players == network_manager.network_players.size():
		is_in_game = true
		game_started.emit()
	if player_inst.is_controlling_player:
		my_player_spawned.emit(player_inst)


func _on_player_died(killing_damage_info: DamageInfo, player: Player):
	if "player_id" in killing_damage_info.attacker_data:
		var killing_player_id = killing_damage_info.attacker_data.player_id as int
		_add_score.rpc(killing_player_id)
	var game_count = _game_count
	var game_player = player.get_node("ManualPlayer").game_player as GamePlayer
	if my_player == player:
		my_player = null
	await get_tree().create_timer(spawn_interval).timeout
	if game_count != _game_count:
		return
	_spawn_player_randomly(game_player.network_player.multiplayer_id)


func _spawn_player_randomly(id: int):
	_spawn_player.rpc(id, randi_range(0, level_manager.spawnpoints.size() - 1))


@rpc("authority", "call_local", "reliable")
func _add_score(player_id: int):
	var player = get_player(player_id)
	player.score += 1
