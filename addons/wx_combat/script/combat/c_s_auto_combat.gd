extends Area3D


var characters_in_view : Dictionary[Node3D,float]
var character_in_eyes : Node3D



func _ready() -> void:
	body_entered.connect(_add_character)
	body_exited.connect(_remove_character)

func _process(delta: float) -> void:
	pass


func _add_character(body:Node3D) -> void:
	if body.is_in_group("player"):
		character_in_eyes = body
	
func _remove_character(body:Node3D) -> void:
	pass
