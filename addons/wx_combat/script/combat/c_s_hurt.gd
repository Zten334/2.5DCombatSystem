extends CollisionShape3D
class_name HurtComp


#region HURT_TIMER 受伤逻辑
enum HurtType{
	STUN = 0,
	LAUNCH = 1,
	PO = 2,
}

#测试用，受击时不同状态下的持续时长
@export var hurt_dir : Dictionary[HurtType,float] = {
	HurtType.STUN:0.2
}

var current_hurt_type : HurtType 

var hurt_timer : float #受击计时器

var is_hurting : bool #是否处于受伤状态

func _hurt_timer(delta:float) -> void:
	
	#每帧倒计时
	hurt_timer -= delta
	#如果计时器小于0，说明当前阶段已经是结束阶段了
	if hurt_timer <= 0:
		hurt_timer = 0
	
	#如果hurt_timer大于0，就说明正在受伤
	is_hurting = hurt_timer > 0
	
func _hurt_start(attack_type:int) -> StringName:
	current_hurt_type = attack_type
	hurt_timer = hurt_dir[attack_type]
	var anim_name :StringName = &"Hurt"
	return anim_name

#endregion


#执行受伤逻辑
#1:晕眩
#2:击飞

func set_shape_scale(scale : Vector3) -> void:
	pass

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	_hurt_timer(delta)
