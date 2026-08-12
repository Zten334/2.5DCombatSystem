extends Area3D


	
	
#region HITCHECK_BOX 攻击检测盒
@export var init_scale : Vector3  #测试用的初始碰撞盒scale

@onready var collision : DynamicBoxCollision = $DynamicBoxCollision

#初始化碰撞大小
func init_collision(target_scale : Vector3) -> void:
	if not collision:
		return
	#设置碰撞盒的尺寸
	collision.set_shape_scale(target_scale)

#endregion


#region ATTACK_TIMER 攻击计时器

#V0.1.3 决定把ability的逻辑抽象至角色层，使AttackComponent的逻辑更加简洁
#V0.1.4 把HitCheck的功能和Attack本身的功能进行了合并 ，统一为AttackComponent
#目前只存储攻击的类型枚举
#region /ATTACK_INFO 攻击（或者说招式）信息
enum AttackType{
	NORMAL = 0,
	KNOCKUP = 1,
}

#设置攻击信息
func set_attack_info(attack_info) -> void:
	
	attack_duration = attack_info.total_duration
	front_time = attack_info.total_duration - attack_info.front_time
	running_time = attack_info.total_duration - attack_info.running_time
	
	hit_check_points = attack_info.hit_check_points
	hit_attack_types = attack_info.hit_attack_types
	
	hit_points_len = attack_info.hit_points_len
	
	print(attack_duration)
	print(front_time)
	print(hit_check_points)

#endregion

#攻击检测的信号
signal hit_check(int)

enum AttackPhase{ #前摇、攻击中、后摇、结束
	FRONT = 0,
	RUNNING = 1,
	REST = 2,
	NONE = 3
}

var current_phase : AttackPhase = AttackPhase.NONE #当前的攻击阶段

var attack_duration : float #攻击的持续时间

var front_time : float #前摇、运行的结束时间
var running_time : float

var hit_points_len : int

var hit_check_points : Array[float] #触发碰撞检测的时间节点
var hit_attack_types : Array[AttackType] #每次触发碰撞检测时的攻击类型

var current_point : int #当前要检测的时间点的索引

var attacking_timer : float #攻击计时器，用以分隔不同的攻击阶段

var attacking_speed   #测试，攻击速度修正



#运行攻击计时器的规则
func _attack_timer(delta:float) -> void:
	#print(current_phase)
	#每帧倒计时
	attacking_timer -= delta
	#如果计时器小于0，说明当前阶段已经是结束阶段了
	if attacking_timer <= 0:
		current_phase = AttackPhase.NONE
		attacking_timer = 0
	else:
		#如果时间大于fronttime，也就是开始攻击但没没过front节点，就把状态设置为FRONT
		if attacking_timer > front_time and (current_phase == AttackPhase.NONE or current_phase == AttackPhase.REST):
			current_phase = AttackPhase.FRONT
		#如果时间已经过了front的节点且状态是front，就变为running
		if attacking_timer <= front_time and current_phase == AttackPhase.FRONT:
			current_phase = AttackPhase.RUNNING
		#同理变为rest
		if attacking_timer <= running_time and current_phase == AttackPhase.RUNNING:
			current_phase = AttackPhase.REST
	
	#判断是否到达了攻击判断触发点
	if current_phase == AttackPhase.RUNNING:
	#这里，因为设定的时候，时间轴是正向的，而倒计时是反向的，所以需要从后
	#往前进行判断
		#current_point不能为0，否则会越界
		if current_point < hit_points_len and attacking_timer <= (attack_duration - hit_check_points[current_point]):  
			check_hit(hit_attack_types[current_point]) #进行一次碰撞判断
			
			hit_check.emit(current_point) #发出攻击碰撞检测的信号
			
			current_point -= 1 #先移动当前current_point

#攻击开始
func attack_start() -> void:
	
	attacking_timer = attack_duration
	current_point = 0

#endregion



#region EXCUTE_ATTACKING 执行攻击效果


#检测攻击碰撞
func check_hit(attack_type : int) -> void:
	var hits = get_overlapping_bodies()
	for hit in hits:
		if hit.has_method("hurt"):
			hit.hurt(attack_type)


#endregion

#region CLASK_FUNC 钩子函数
func _ready() -> void:
	#初始化能力信息
	init_collision(init_scale) 

func _process(delta: float) -> void:
	_attack_timer(delta)
#endregion
