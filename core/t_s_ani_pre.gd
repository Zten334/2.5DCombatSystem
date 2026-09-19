@tool
extends AnimationPlayer


@export var debug_chara : CharacterBody3D

@export var start_pre : bool

func _ready() -> void:
	pass



func _process(delta: float) -> void:
	
	if not Engine.is_editor_hint():
		return
	
	

func _physics_process(delta: float) -> void:
	if not Engine.is_editor_hint():
		return
		
	if debug_chara and start_pre:
		#print(debug_chara.velocity)
		pass
