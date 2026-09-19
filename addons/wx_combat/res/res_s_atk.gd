extends Resource
class_name AttackResource

enum AttackType{
	NORMAL = 0,
	KNOCKUP = 1,
}

@export var attack_id : StringName
#0:一般攻击,1:击飞
@export var total_duration : float #总持续时长

@export var front_time : float #前摇结束的时间点，running结束的时间点
@export var running_time : float

@export var hit_check_points : Array[float] = [] #攻击检测点

@export var hit_attack_types : Array[AttackType] = [] #每个攻击的类型

@export var hit_points_len : int
