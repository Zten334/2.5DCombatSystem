extends Resource
class_name CombatAbility

#region status
#测试
#名字与数值
class Modifier:
	var name : StringName
	var value : float

#伤害时间点
#时间
#伤害倍率
#伤害特殊词条：比如穿透、暴击增幅、回血等
class Demage_Point:
	var time : float
	var demage_rate : float
	var demage_modifier : StringName

#buff时间点
#时间点
#buff的名称、等级、层数
#buff的持续时间
class Buff_Point:
	var time : float
	var buff_name : StringName
	var buff_level : int
	var buff_stack : int
	var buff_duration : float

#endregion
#总持续时长
@export var total_duration : float

#前摇结束的时间点，running结束的时间点
@export var front_time : float
@export var running_time : float

#攻击检测点
@export var hit_check_points : Array[float]
