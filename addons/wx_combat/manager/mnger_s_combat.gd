extends Node
class_name CombatManager

#先用Export，后面可以考虑改成动态加载

@export var chraras : Array[CombatChara]

func _ready() -> void:
	#遍历，绑定信号
	for chara in chraras:
		pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
