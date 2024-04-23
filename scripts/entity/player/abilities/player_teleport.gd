class_name PlayerTeleport
extends Node


@export var player: Player
@export var player_move: PlayerMove
@export var body_shape_cast: ShapeCast2D
@export var tp_source_fx: FX
@export var tp_dest_fx: FX

var manual_player: ManualPlayer


func _ready():
	manual_player = player.get_node_or_null("ManualPlayer")


# Used for teleporting player in abilities
func _receive_ability_data(data: Dictionary):
	print("receive teleport: ", data)
	var tp_position = data.position as Vector2
	body_shape_cast.global_position = tp_position
	body_shape_cast.force_shapecast_update()
	print("body collision count: ")
	for i in body_shape_cast.get_collision_count():
		if (body_shape_cast.get_collider(i) as Node).is_in_group("Wall"):
			print("tp into wall, aborting")
			return
	var old_pos = player.global_position
	player_move.teleport_to(tp_position)
	print("finished tp")
	_play_fx.rpc(old_pos, tp_position)


@rpc("authority", "call_local", "reliable")
func _play_fx(source_pos: Vector2, dest_pos: Vector2):
	print("player fx pos: ", source_pos, " dest: ", dest_pos)
	if tp_source_fx:
		tp_source_fx.global_position = source_pos
		tp_source_fx.play()
	if tp_dest_fx:
		tp_dest_fx.global_position = dest_pos
		tp_dest_fx.play()
