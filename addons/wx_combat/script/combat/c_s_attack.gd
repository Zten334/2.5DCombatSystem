extends Area3D
class_name AttackComp


#region HITCHECK_BOX 攻击检测盒
@export var init_scale : Vector3  #测试用的初始碰撞盒scale

@onready var collision : DynamicBoxCollision = $DynamicBoxCollision

var is_right : bool = true

#初始化碰撞大小
func collision_init(target_scale : Vector3) -> void:
	if not collision:
		return
	#设置碰撞盒的尺寸
	collision.set_shape_scale(target_scale)

func flip(right) -> void:
	if right:
		position.x = 0.17
		rotation.y = 0
	else:
		position.x = -0.17
		rotation.y = PI
	#反转一下即可
	is_right = right

#endregion

#region ATTACK_INFO 攻击（或者说招式）信息
enum AttackType{
	NORMAL = 0,
	KNOCKUP = 1,
}

#攻击数据的基础信息
class AbilityInfo:
	
	var attack_type : int
	#0:一般攻击,1:击飞
	var total_duration : float #总持续时长
	
	var front_time : float #前摇结束的时间点，running结束的时间点
	var running_time : float
	
	var hit_check_points : Array[float] #攻击检测点
	var hit_attack_types : Array[AttackType] #每个攻击的类型
	
	var hit_points_len : int

var attack_info : Array[AbilityInfo] #普通攻击的所有派生数组

var attack_index : int  = 0#普通攻击当前的派生顺序


func init_ability_info() -> void:
	#初始化一个ability_info
	
	var ability_info = AbilityInfo.new()
	ability_info.total_duration = 0.25
	ability_info.front_time = 0.1
	ability_info.running_time = 0.2
	ability_info.hit_check_points.append(0.12)
	ability_info.hit_attack_types.append(AttackType.NORMAL)
	ability_info.hit_points_len = 1
	
	#加入到数组中
	attack_info.append(ability_info)
	
	ability_info = AbilityInfo.new()
	ability_info.total_duration = 0.25
	ability_info.front_time = 0.1
	ability_info.running_time = 0.25
	ability_info.hit_check_points.append(0.12)
	ability_info.hit_attack_types.append(AttackType.NORMAL)
	ability_info.hit_points_len = 1
	
	#加入到数组中
	attack_info.append(ability_info)
	
	ability_info = AbilityInfo.new()
	ability_info.total_duration = 0.25
	ability_info.front_time = 0.05
	ability_info.running_time = 0.2
	ability_info.hit_check_points.append(0.075)
	ability_info.hit_attack_types.append(AttackType.NORMAL)
	ability_info.hit_points_len = 1
	
	#加入到数组中
	attack_info.append(ability_info)
	

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
	print(hit_points_len)

#endregion

#region ATTACK_TIMER 攻击计时器
#攻击检测的信号
signal hit_check(int,Array)
#切换状态的信号
signal swith_phase(int) 


enum AttackPhase{ #前摇、攻击中、后摇、结束
	FRONT = 0,
	RUNNING = 1,
	REST = 2,
	NONE = 3
}

var cur_phase = AttackPhase.NONE

#是否正在进行攻击，即attack_timer是否大于0
#可舍弃
var is_attacking : bool = false

var attack_duration : float #攻击的持续时间

var enter_front : bool = false
var front_time : float #前摇的结束时间
var over_front : bool = false #当前是否已经经过了前摇
var running_time : float #同上
var over_running : bool = false

var hit_points_len : int

var hit_check_points : Array[float] #触发碰撞检测的时间节点
var hit_attack_types : Array[AttackType] #每次触发碰撞检测时的攻击类型

var current_point : int #当前要检测的时间点的索引

var attacking_timer : float #攻击计时器，用以分隔不同的攻击阶段

var attacking_speed   #测试，攻击速度修正

#运行攻击计时器的规则
func _attack_timer(delta:float) -> void:
	#print(owner.name,' ',str(cur_phase))
	#每帧倒计时
	attacking_timer -= delta
	#如果计时器小于0，说明当前阶段已经是结束阶段了
	if attacking_timer <= 0:
		is_attacking = false
		cur_phase = AttackPhase.NONE
		attacking_timer = 0
	else:
		is_attacking = true
		#如果时间大于fronttime，也就是开始攻击但没没过front节点，就把状态设置为FRONT
		if attacking_timer > front_time and not enter_front:
			cur_phase = AttackPhase.FRONT  #0:前摇
			enter_front = true
		#如果时间已经过了front的节点且状态是front，就变为running
		if attacking_timer <= front_time and not over_front:
			cur_phase = AttackPhase.RUNNING  #1:攻击中
			over_front = true
		#同理变为rest
		if attacking_timer <= running_time and not over_running:
			cur_phase = AttackPhase.REST  #2:后摇
			over_running = true
	
	#判断是否到达了攻击判断触发点
	#这里，设定的时候，时间轴是正向的，而倒计时是反向的
	#所以计算具体时间的时候要反向一下
	if current_point < hit_points_len and attacking_timer <= (attack_duration - hit_check_points[current_point]):  
		
		check_hit(hit_attack_types[current_point]) #进行一次碰撞判断
	
		current_point += 1 #执行后移动当前current_point

#攻击开始,一次搞定所有逻辑
#将attack_info从数组中抽取出来，然后放进逻辑中
#返回的是攻击动画的名称
func attack_start() -> StringName:
	if cur_phase == AttackPhase.RUNNING:
		return ''
	
	var att_info = attack_info[attack_index]
	set_attack_info(att_info)
	
	attacking_timer = attack_duration
	current_point = 0
	#把三个标志位重新归零一下
	enter_front = false
	over_front = false
	over_running = false
	
	start_combo_timer()
	
	#index 从1开始
	
	var anim_index = attack_index + 1
	
	attack_index += 1
	
	if attack_index >= len(attack_info):
		attack_index = 0
	var anim_name = StringName("Light_Attack_0" + str(anim_index))
	
	return anim_name
#endregion

#region 连击计数
signal combo_refresh

var combo_timer : float = 0
var can_combo_t : bool = false

#进行连招计时
func _combo_process(delta:float) -> void:
	if not can_combo_t:
		return
	combo_timer -= delta
	if combo_timer < 0:
		can_combo_t = false
		attack_index = 0
		combo_timer = 0
		
		
func start_combo_timer() -> void:
	combo_timer = 1  #假设为1s
	can_combo_t = true
	
#endregion

#region EXCUTE_ATTACKING 执行攻击效果

#检测攻击碰撞
func check_hit(attack_type:int) -> void:
	var hits = get_overlapping_bodies()
	hit_check.emit(attack_type,hits) #发出攻击碰撞检测的信号


#endregion

#region CLASK_FUNC 钩子函数
func _ready() -> void:
	init_ability_info()
	#初始化能力信息
	collision_init(init_scale) 

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	_attack_timer(delta)
	_combo_process(delta)
#endregion
