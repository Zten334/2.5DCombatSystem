extends Node3D

@export var owning_character : CombatChara

@export_category("Inputs")
@export var up : StringName
@export var down : StringName
@export var left : StringName
@export var right : StringName

@export var jump : StringName

@export_category("Combat")
@export var attack : StringName

func _ready() -> void:
	_data_init()

func _process(delta: float) -> void:
	_moving_input_handling(delta)


#region CONTROLFUNC 控制函数
#将移动输入施加到角色身上
func _moving_input_handling(delta:float) -> void:
	if !owning_character:
		return
		
	var input = Input.get_vector(left,right,up,down)
	if owning_character.has_method("accel_prcs") and input != Vector2.ZERO:
		owning_character.accel_prcs(input,delta)
	
	if Input.is_action_just_pressed(attack) and owning_character.has_method("light_attack"):
		owning_character.light_attack()

#终止对角色的控制
func _ctr_end() -> void:
	owning_character = null
#endregion


#region DATA_UI 数据UI更新
@onready var hp_bar = $HpBar

#初始化数据
func _data_init() -> void:
	if not owning_character:
		return
		
	owning_character.death.connect(_ctr_end)
	owning_character.hp_chg.connect(_data_get_ui_update)
	
	var max_hp = owning_character.max_hp
	
	hp_bar.max_value = max_hp
	
	hp_bar.value = max_hp
	

#过程中更新数据和UI
func _data_get_ui_update(value) -> void:
	#print("hp change")
	hp_bar.value = value


#endregion
