extends Resource
class_name AbilityResource

enum EventType{
	HIT_NOR = 0,
	BUFF = 1,
}


@export var ability_id : StringName
#0:一般攻击,1:击飞
@export var total_duration : float #总持续时长

@export var front_time : float #前摇结束的时间点，running结束的时间点
@export var running_time : float

@export var event_check_points : Array[float] = [] #事件检测点

@export var event_types : Array[int] = [] #每个事件的类型

@export var event_points_len : int
