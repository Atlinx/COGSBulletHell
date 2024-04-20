class_name PaletteSwap
extends Node


@export var visuals: Array[Sprite2D]
@export var self_modulate_0: Array[Node2D]
@export var self_modulate_1: Array[Node2D]
@export var self_modulate_2: Array[Node2D]
@export var self_modulate_3: Array[Node2D]
@export var palette: ColorPalette


func use_palette(_palette: ColorPalette):
	palette = _palette
	for visual in visuals:
		palette.apply_to_recolor_material(visual.material as ShaderMaterial)
	for self_modulate_inst in self_modulate_0:
		self_modulate_inst.self_modulate = palette.color_1
	for self_modulate_inst in self_modulate_1:
		self_modulate_inst.self_modulate = palette.color_2
	for self_modulate_inst in self_modulate_2:
		self_modulate_inst.self_modulate = palette.color_3
	for self_modulate_inst in self_modulate_3:
		self_modulate_inst.self_modulate = palette.color_4
