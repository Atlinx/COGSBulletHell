class_name AbilityIndicator
extends ColorRect



@export var texture_rect: TextureRect
@export var cooldown_color_rect: ColorRect
@export var cooldown_label: Label

var ability: PlayerAbility


func post_construct(_ability: PlayerAbility):
	ability = _ability
	visible = ability != null
	if ability:
		texture_rect.texture = ability.ability_icon
		ability.cooldown_started.connect(_on_cooldown_started)
		ability.cooldown_over.connect(_on_cooldown_over)


func _on_cooldown_started():
	cooldown_color_rect.visible = true


func _on_cooldown_over():
	cooldown_color_rect.visible = false


func _process(delta):
	if not is_instance_valid(ability):
		ability = null
		_on_cooldown_over()
	if ability and ability.on_cooldown:
		cooldown_label.text = "%.1f" % ability._cooldown_timer
