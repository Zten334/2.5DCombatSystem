extends CharacterBody3D

#region BASIC_DATA
@export_category("PhyscisParaData")
#越大下落得越快
@export var gravity_rate : float
@export_category("CharacterNormalData")
@export var max_speed : float
@export var acceleration : float
@export var jump_velocity : float


var stay_air : bool = false
#endregion

#region CLASK_FUNC
func _process(delta: float) -> void:
	#physics
	_check_gravity(delta)
	#animation
	_update_sprite_forwad()
	#combat
	_attack_progress(delta)
	

func _physics_process(delta: float) -> void:
	#animation
	_update_animator_data()
	#locomotion
	move_and_slide()
#endregion

#region RESOURCE


#endregion

#region ANIMATION
@onready var animation_tree = $AnimationTree
@onready var sprite3d = $CharacterSprite
#调整Sprite的朝向
func _update_sprite_forwad() -> void:
	if !sprite3d:
		return
	#根据x方向的速率调整sprite的左右
	if velocity.x > 0 :
		sprite3d.scale.x = 1
	elif velocity.x < 0 :
		sprite3d.scale.x = -1
		
#更新AnimationTree中的运动相关数据
func _update_animator_data() -> void:
	if !animation_tree:
		return
	animation_tree.update_locomotion_data(velocity)

func _play_montage(name) -> void:
	if !animation_tree:
		return
	animation_tree.play_montage(name)
#endregion

#region LOCOMOTIONS
#应用重力
func _check_gravity(delta: float) -> void:
	if stay_air:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_rate


func jump() -> void:
	velocity.y = jump_velocity

##2D运动

#为当前角色施加加速度
#forward:前进的方向，0到1之间，Vector3
#delta：速度增量
func accelerate(forward,delta) -> void:
	var new_vel = forward.normalized() * max_speed	
	velocity.x = move_toward(velocity.x,new_vel.x,delta * acceleration)
	velocity.z = move_toward(velocity.z,new_vel.y,delta * acceleration)


#直接设置当前角色的速度
#forward:方向
#rate:与最大速率的比例
func assign_velocity(forward,rate = 1) -> void:
	velocity.x = forward.x * rate * max_speed
	velocity.z = forward.y * rate * max_speed
#endregion

#region COMBAT
@onready var attack_component = $AttackComponent
@onready var combat_resource_component = $CombatResourceComponent

#region COMBATSTATEMACHINE
enum AttackPhase{ #前摇、攻击中、后摇、结束
	FRONT,
	RUNNING,
	REST,
	NONE
}


var current_phase : AttackPhase = AttackPhase.NONE #当前的攻击阶段

var total_duration : float #攻击的持续时间

var front_time : float #前摇、运行的结束时间
var running_time : float

var hit_check_points : Array[float] #触发碰撞检测的时间节点
var current_point : int #当前要检测的时间点的索引


var attacking_timer : float #攻击计时器，用以分隔不同的攻击阶段

#endregion

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
		if current_point >= 0 and attacking_timer <= (total_duration - hit_check_points[current_point]):
			current_point -= 1 #先移动当前current_point
			_excute_hit_check()  #进行一次碰撞判断 

#轻攻击（暂定），需要去招式资源组件中读取，然后根据index进行选择
func light_attack() -> void:
	#首先我得知道有哪些招式，然后再选择使用哪个
	if not combat_resource_component:
		print('You Have No Combat Rousource Yet!')
		return
	#如果当前正在攻击阶段，则跳过
	if current_phase == AttackPhase.RUNNING:
		return
	_copy_ability_data(1)
	
	#启动timer
	attacking_timer = total_duration
	current_point = len(hit_check_points) - 1
	#将当前攻击阶段设为FONT
	#current_phase = AttackPhase.FRONT
	#播放动画
	_play_montage(&"Light_Attack")


func hurt() -> void:
	print(name," is hurt!")

#region TOOLFUNC
#读取ability中的数据
func _copy_ability_data(index : int) -> void:
	var ability : CombatAbility = combat_resource_component.get_ability(index)
	
	total_duration = ability.total_duration
	front_time = ability.total_duration - ability.front_time
	running_time = ability.total_duration - ability.running_time
	
	hit_check_points = ability.hit_check_points
	
func _excute_hit_check() -> void:
	
	if not attack_component:
		return
	attack_component.check_hit()

#endregion
#endregion

#region STATS
var stats_component

var max_hp
var hp

var base_attack   #基础攻击
var attack		#当前实际攻击
var base_defense #基础防御
var defense		#当前防御
var base_speed   #基础速度
var speed		#当前速度
var base_crit_rate  #基础暴击率
var crit_rate    #当前暴击率


#endregion
