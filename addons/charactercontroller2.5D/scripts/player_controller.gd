extends Camera3D

@export var owning_character : CharacterBody3D

@export_category("Inputs")
@export var up : StringName
@export var down : StringName
@export var left : StringName
@export var right : StringName

@export var jump : StringName


func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_handling_moving_input(delta)


#region CONTROLFUNC
#将移动输入施加到角色身上
func _handling_moving_input(delta:float) -> void:
	if !owning_character:
		return
		
	var input = Input.get_vector(left,right,up,down)
	if owning_character.has_method("accelerate"):
		owning_character.accelerate(input,delta)
	
	if Input.is_action_just_pressed("attack") and owning_character.has_method("light_attack"):
		owning_character.light_attack()

#endregion
