extends CharacterBody3D

#region BASIC_DATA 基本信息，如物理参数
@export_category("FanctionInfo")#阵营信息
@export_enum("HERO:1","ENEMY:2","NONE:3") var faction : int

@export_category("PhyscisParaData")
#越大下落得越快
@export var gravity_rate : float
@export var friction_strength : float
@export_category("CharacterNormalData")
@export var max_speed : float
@export var acceleration : float
@export var jump_velocity : float


var stay_air : bool = false



#endregion

#region LOCOMOTIONS 人物运动
#应用重力
func _check_gravity(delta: float) -> void:
	if stay_air:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_rate

func jump() -> void:
	velocity.y = jump_velocity

##2D运动
#应用摩擦力
func _check_friction(delta:float) -> void:
	velocity.x = move_toward(velocity.x,0,delta * friction_strength)
	velocity.z = move_toward(velocity.z,0,delta * friction_strength)

#为当前角色施加加速度
#forward:前进的方向，任意长度，Vector2
#delta：速度增量
#暂时：攻击时不能被加速
func accelerate(forward,delta) -> void:
	if current_phase != AttackPhase.NONE:
		return
	var new_vel = forward.normalized() * max_speed
	#var new_forward = Vector3(new_vel.x - velocity.x,0,new_vel.y - velocity.z)
	#new_forward = new_forward.normalized()
	#这里使用的是move_toward，匀加速运动
	velocity.x = move_toward(velocity.x,new_vel.x,delta * acceleration)
	velocity.z = move_toward(velocity.z,new_vel.y,delta * acceleration)
	#velocity += new_forward * delta * acceleration
	
#直接设置当前角色的速度
#forward:方向
#rate:与最大速率的比例
func assign_velocity(forward,rate = 1) -> void:
	velocity.x = forward.x * rate * max_speed
	velocity.z = forward.y * rate * max_speed
#endregion

#region ANIMATION 动画控制
@onready var animation_tree = $AnimationTree
@onready var sprite3d = $AnimatedSprite3D
#调整Sprite的朝向
func _update_sprite_forwad() -> void:
	if !sprite3d:
		return
	#根据x方向的速率调整sprite的左右
	if velocity.x > 0 :
		sprite3d.flip_h = false
	elif velocity.x < 0 :
		sprite3d.flip_h = true
		
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

#region AI_CONTROLLER 提供给AI控制器的接口
var is_ctring : bool #是否正在被控制

func get_attack_area_size() -> Vector3:
	if not attack_component:
		return Vector3.ZERO
	return attack_component.init_scale

#设置当前的要追踪的实体
func set_is_ctring(value:bool) : is_ctring = value


func _ai_progress(delta:float) -> void:
	pass
#endregion

#region STATS 数值系统
@onready var stats_component = $StatsComponent
signal death #死亡时发出的信号

var is_hp_zero : bool = false #标志位，供其他组件判断hp是否为0了

func _update_stats_info() -> void:
	if not stats_component:
		return
	if stats_component.hp < 0 and not is_hp_zero:
		is_hp_zero = true
		death.emit()
		print(name," is dead!")



#endregion

#region COMBAT 战斗系统

@onready var attack_component = $AttackComponent

func _init_faction_collision() -> void:
	collision_layer = faction
	
	match faction:
		1:
			set_collision_mask_value(1,false)
			set_collision_mask_value(2,true)
		2:
			set_collision_mask_value(1,true)
			set_collision_mask_value(2,false)
			
	set_collision_mask_value(6,true) #统一和block层碰撞
	
	if not attack_component:
		return
		
	attack_component.collision_layer = 0
	#attack_component.init_collision
	match faction:
		1:
			attack_component.set_collision_mask_value(1,false)
			attack_component.set_collision_mask_value(2,true)
		2:
			attack_component.set_collision_mask_value(1,true)
			attack_component.set_collision_mask_value(2,false)
	
	
#region /ATTACK_INFO 战斗招式等相关信息
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
	
	
#endregion

#region /ATTACK_TIMER 战斗逻辑

enum AttackPhase{ #前摇、攻击中、后摇、结束
	FRONT = 0,
	RUNNING = 1,
	REST = 2,
	NONE = 3
}

var current_phase : AttackPhase = AttackPhase.NONE #当前的攻击阶段

var attacking_speed   #测试，攻击速度修正

func _attack_init() -> void:
	if not attack_component:
		return
	#连接碰撞检测和攻击阶段切换的信号
	attack_component.hit_check.connect(_excute_hit_check)
	attack_component.swith_phase.connect(_switch_phase)
	#连接范围检测的信号
	attack_component.body_entered.connect(_body_enter_attarea)

#运行攻击计时器的规则
func _attack_progress(delta:float) -> void:
	if not attack_component:
		return
	#将攻击阶段与component同步,即如果不是处于攻击状态，就将攻击阶段设为NONE
	if not attack_component.is_attacking:
		current_phase = AttackPhase.NONE
	
	#print(name,' ',current_phase)

#轻攻击（暂定），需要去招式资源组件中读取，然后根据index进行选择
func light_attack() -> void:
	#首先我得知道有哪些招式，然后再选择使用哪个
	if not attack_component:
		print('You Have No AttackComponent Yet!')
		return
	#如果当前正在攻击阶段，则跳过
	if current_phase == AttackPhase.RUNNING:
		return
	
	attack_index += 1
	if attack_index >= len(attack_info):
		attack_index = 0
	
	
	#把攻击信息送至AttackComponent并启动timer
	attack_component.set_attack_info(attack_info[attack_index])
	attack_component.attack_start()
	
	#播放动画
	var anim_name = StringName("Light_Attack_0" + str(attack_index + 1))
	_play_montage(anim_name)

#切换当前攻击状态
func _switch_phase(new_phase:int) -> void:
	print("phase has changed!")
	current_phase = new_phase

#region //TOOLFUNC 工具函数，主要是信号绑定相关的
signal body_enter_attarea(Node3D)

#接收到碰撞检测信号后执行，主要可让各个component之间通信
func _excute_hit_check(hit_check_point:int) -> void:
	if not attack_component:
		return
	print(name," The Hit Point ",hit_check_point," Is Trigger!")

#接受攻击范围检测信号后执行，意为有body进入了攻击范围
func _body_enter_attarea(body:Node3D) -> void:
	body_enter_attarea.emit(body)

#endregion

#endregion

#region /HURT 受伤逻辑

enum HurtType{
	STUN = 0,
	LAUNCH = 1,
	PO = 2,
}

#测试用，受击时不同状态下的持续时长
var hurt_dir : Dictionary[HurtType,float] = {
	HurtType.STUN:0.2
}

var current_hurt_type : HurtType 

var hurt_timer : float #受击计时器
var is_hurting : bool #是否处于受伤状态

func _hurt_progress(delta:float) -> void:
	#print(is_hurting)
	
	#每帧倒计时
	hurt_timer -= delta
	#如果计时器小于0，说明当前阶段已经是结束阶段了
	if hurt_timer <= 0:
		hurt_timer = 0
	
	#如果hurt_timer大于0，就说明正在受伤
	is_hurting = hurt_timer > 0
	
#匹配攻击类型,暂时用枚举
#与hurt_type是一一对应的
func hurt(attack_type) -> void:
	
	current_hurt_type = attack_type
	hurt_timer = hurt_dir[attack_type]
	
	if not animation_tree:
		return
	animation_tree.play_montage(&"Hurt")
	
	print(name," is hurt!")
	

	

#endregion


#endregion

#region RESOURCE 资源


#endregion


#region CLASK_FUNC 自带的钩子函数
func _ready() -> void:
	init_ability_info()
	_attack_init()
	_init_faction_collision()

func _process(delta: float) -> void:
	#stats 处理数值相关的逻辑，第一优先
	_update_stats_info()
	
	#animation
	_update_sprite_forwad()
	#ai
	
	#combat
	_attack_progress(delta)
	_hurt_progress(delta) 
	

func _physics_process(delta: float) -> void:
	#physics 检查重力和摩擦力
	_check_gravity(delta)
	_check_friction(delta)
	#animation
	_update_animator_data()
	#locomotion
	move_and_slide()
#endregion
