class_name Player
extends CharacterBody2D


signal died(killing_damage_info: DamageInfo)


@export var palette_swap: PaletteSwap
@export var team: Team
@export var health: Health

var palette: ColorPalette
var game_player: GameManager.GamePlayer
var is_controlling_player: bool


func pre_construct(_palette: ColorPalette, _team: String):
	palette = _palette
	palette_swap.use_palette(palette)
	team.team = _team


func _ready():
	health.died.connect(_on_died)


func _on_died(killing_damage_info: DamageInfo):
	died.emit(killing_damage_info)
