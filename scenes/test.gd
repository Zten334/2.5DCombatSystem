@tool
extends CharacterBody3D

@export var vel : Vector3:
	set(value):
		vel = value
		if start_pre:
			position += vel * get_process_delta_time()

@export var start_pre : bool


func _ready() -> void:
	pass

func _process(delta):
	pass


func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		move_and_slide()
	elif not start_pre:
		position = Vector3.ZERO
