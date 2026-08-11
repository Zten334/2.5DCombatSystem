extends Node

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

var current_point : int #当前要检测的时间点的索引

var attacking_timer : float #攻击计时器，用以分隔不同的攻击阶段

var attacking_speed   #测试，攻击速度修正


#运行攻击计时器的规则
func _attack_progress(delta:float) -> void:
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
			hit_check.emit(current_point)  #进行一次碰撞判断
			
			current_point -= 1 #先移动当前current_point
