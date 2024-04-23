@tool
class_name Team
extends Node


@export var entity_owner: Node2D
@export var entity_owner_type: String = ""
@export var _entity_owner_data: Dictionary
var entity_owner_data: Dictionary = {}

@export var team: String
@export var source_team: Team :
	get:
		return source_team
	set(value):
		source_team = value
		if Engine.is_editor_hint():
			notify_property_list_changed()


func _ready():
	copy_source_team()
	if entity_owner_type:
		entity_owner_data.type = entity_owner_type
	if _entity_owner_data:
		entity_owner_data.merge(_entity_owner_data)


func copy_source_team():
	if source_team:
		copy_team(source_team)


## Copies all the values
## from a team node 1-for-1
func copy_team(_team: Team):
	entity_owner = _team.entity_owner
	team = _team.team
	entity_owner_data = _team.entity_owner_data


func _validate_property(property):
	if property.name in ["entity_owner", "team", "_entity_owner_data", "entity_owner_type"] and source_team:
		property.usage = PROPERTY_USAGE_NO_EDITOR
