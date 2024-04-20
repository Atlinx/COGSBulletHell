class_name ColorPalette
extends Resource


@export var color_1: Color
@export var color_2: Color
@export var color_3: Color
@export var color_4: Color


func apply_to_recolor_material(material: ShaderMaterial):
	material.set_shader_parameter("replace_0", color_1)
	material.set_shader_parameter("replace_1", color_2)
	material.set_shader_parameter("replace_2", color_3)
	material.set_shader_parameter("replace_3", color_4)
