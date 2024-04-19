class_name Team
extends Node


@export var entity_owner: Node2D
@export var team: String


## Copies all the values
## from a team node 1-for-1
func copy_team(_team: Team):
	entity_owner = _team.entity_owner
	team = _team.team


## Takes a team node's team,
## but takes it's parent as
## the new owner
func inherit_team(_team: Team):
	entity_owner = _team.get_parent()
	team = _team.team
