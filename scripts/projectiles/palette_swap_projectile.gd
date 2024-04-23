@tool
class_name PaletteSwapProjectile
extends Node


@export var palette: ColorPalette :
	get:
		return _palette
	set(value):
		_palette = value
		if Engine.is_editor_hint() and _palette:
			_set_palette(_palette)
var _palette: ColorPalette

@onready var projectile: Projectile = get_parent()


func _ready():
	if Engine.is_editor_hint():
		if _palette:
			_set_palette(_palette)
		return
	var data_palette = load(projectile.data.get("palette"))
	if data_palette:
		_set_palette(data_palette)


func _set_palette(new_palette: ColorPalette):
	_palette = new_palette
	if _palette:
		for child in get_children():
			if child is PaletteSwap:
				child.use_palette(new_palette)
