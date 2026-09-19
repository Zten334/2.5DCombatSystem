extends CharacterBody3D

@export_category("PhyscisParaData")
#越大下落得越快
@export var gravity_rate : float = 1
@export var friction_strength : float = 15
@export_category("CharacterNormalData")
@export var max_speed : float = 3
@export var acceleration : float = 30
@export var jump_velocity : float = 3

var stay_air : bool = false
var is_air : bool = false


func _physics_process(delta: float) -> void:
	pass

	move_and_slide()
