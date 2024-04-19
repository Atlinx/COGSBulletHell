extends Label


@onready var projectile: Projectile = get_parent()


func _ready():
	text = projectile.name
