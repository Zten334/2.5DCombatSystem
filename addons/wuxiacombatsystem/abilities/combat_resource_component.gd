extends Node

@export var current_abilities : Array[CombatAbility]



func get_ability(index : int) -> CombatAbility:
	return current_abilities[index - 1]
