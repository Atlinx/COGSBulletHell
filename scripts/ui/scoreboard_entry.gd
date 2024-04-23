class_name ScoreboardEntry
extends HBoxContainer


@export var player_color_rect: ColorRect
@export var score_label: Label
@export var username_label: Label

var game_player: GameManager.GamePlayer
var _score_tween: Tween


func construct(_game_player: GameManager.GamePlayer):
	game_player = _game_player
	player_color_rect.color = game_player.palette.color_2
	score_label.text = str(0)
	username_label.text = _game_player.network_player.username
	game_player.score_updated.connect(_on_score_updated)


func _on_score_updated(amount: int):
	score_label.text = str(amount)
	if _score_tween and _score_tween.is_running():
		_score_tween.kill()
	_score_tween = create_tween()
	_score_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	score_label.scale = Vector2(1.5, 1.5)
	_score_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.5)
