extends CharacterBody3D

#region BASIC_DATA 基本信息，如物理参数
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
#forward:前进的方向，0到1之间，Vector3
#delta：速度增量
func accelerate(forward,delta) -> void:
	var new_vel = forward.normalized() * max_speed
	var new_forward = Vector3(new_vel.x - velocity.x,0,new_vel.y - velocity.z)
	new_forward = new_forward.normalized()
	#velocity.x = move_toward(velocity.x,new_vel.x,delta * acceleration)
	#velocity.z = move_toward(velocity.z,new_vel.y,delta * acceleration)
	velocity += new_forward * delta * acceleration
	
	
#直接设置当前角色的速度
#forward:方向
#rate:与最大速率的比例
func assign_velocity(forward,rate = 1) -> void:
	velocity.x = forward.x * rate * max_speed
	velocity.z = forward.y * rate * max_speed
#endregion

#region STATS 数值系统
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

#region COMBAT 战斗系统
@onready var hit_check_component = $HitCheckComponent
@onready var combat_resource_component = $CombatResourceComponent

@onready var ability_component = $AbilityComponent

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

var attack_index : int #普通攻击当前的派生顺序


func init_ability_info() -> void:
	#初始化一个ability_info
	var ability_info = AbilityInfo.new()
	ability_info.total_duration = 0.8
	ability_info.front_time = 0.1
	ability_info.running_time = 0.6
	ability_info.hit_check_points.append(0.3)
	ability_info.hit_check_points.append(0.5)
	ability_info.hit_attack_types.append(AttackType.NORMAL)
	ability_info.hit_attack_types.append(AttackType.KNOCKUP)
	
	#加入到数组中
	attack_info.append(ability_info)
	
	
#endregion

#region /ATTACK_SM 攻击状态机

enum AttackPhase{ #前摇、攻击中、后摇、结束
	FRONT = 0,
	RUNNING = 1,
	REST = 2,
	NONE = 3
}

var current_phase : AttackPhase = AttackPhase.NONE #当前的攻击阶段

var attacking_speed   #测试，攻击速度修正


func _init_ability_timer() -> void:
	if not ability_component:
		return
	
	ability_component.hit_check.connect(_excute_hit_check)

#运行攻击计时器的规则
func _attack_progress(delta:float) -> void:
	if not ability_component:
		return
	#将攻击阶段与component同步
	current_phase = ability_component.current_phase

			
			 

#region //ATTACK_EXCUTE 具体的攻击效果处理

#轻攻击（暂定），需要去招式资源组件中读取，然后根据index进行选择
func light_attack() -> void:
	#首先我得知道有哪些招式，然后再选择使用哪个
	if not hit_check_component or not ability_component:
		print('You Have No AttackComponent Yet!')
		return
	#如果当前正在攻击阶段，则跳过
	if current_phase == AttackPhase.RUNNING:
		return
	
	_copy_ability_data()
	
	#启动timer,后放入ability_component中
	ability_component.attacking_timer = ability_component.attack_duration
	ability_component.current_point = 0
	
	#将当前攻击阶段设为FONT
	#current_phase = AttackPhase.FRONT
	#播放动画
	_play_montage(&"Light_Attack")

#endregion

#region //TOOLFUNC
#读取ability中的数据
func _copy_ability_data() -> void:
	#从攻击组件中获取，更加合理
	var ability : AbilityInfo = attack_info[attack_index]
	#var ability : CombatAbility = combat_resource_component.get_ability(index)
	
	ability_component.attack_duration = ability.total_duration
	ability_component.front_time = ability.total_duration - ability.front_time
	ability_component.running_time = ability.total_duration - ability.running_time
	
	ability_component.hit_check_points = ability.hit_check_points
	
	ability_component.hit_points_len = ability.hit_points_len
	
	print(ability_component.attack_duration)
	print(ability.front_time)
	print(ability_component.hit_check_points)
	
#进行攻击检测，交由attack_component处理
func _excute_hit_check(hit_check_point:int) -> void:
	if not hit_check_component:
		return
	#暂时用
	#把当前攻击检测点的攻击类型传入
	hit_check_component.check_hit(attack_info[attack_index].hit_attack_types[hit_check_point])

#endregion

#endregion



#region /HURT

enum HurtType{
	STUN = 1,
	LAUNCH = 2,
	PO = 3,
}

#测试用，受击时不同状态下的持续时长
@export var hurt_dir : Dictionary[HurtType,float]

var current_hurt_type : HurtType

var hurt_timer : float #受击计时器
var hurt_duration : float #受击持续时间,可能多余了

func _hurt_progress(delta:float) -> void:
	#每帧倒计时
	hurt_timer -= delta
	#如果计时器小于0，说明当前阶段已经是结束阶段了
	if hurt_timer <= 0:
		hurt_timer = 0
	else:
		pass
		
	#根据当前不同的受伤类型，执行操作
	match current_hurt_type:    
		HurtType.STUN:
			print('i am stun!')
		HurtType.LAUNCH:
			print('i am launch!')
		HurtType.PO:
			print('i am po!')
		_:
			pass
	
#匹配攻击类型,暂时用枚举
#与hurt_type是一一对应的
func hurt(attack_type) -> void:
	
	current_hurt_type = attack_type
	hurt_duration = hurt_dir[attack_type]
	hurt_timer = hurt_duration
	

	

#endregion


#endregion

#region RESOURCE 资源


#endregion

#region ANIMATION 动画控制
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

#region CLASK_FUNC 自带的钩子函数
func _ready() -> void:
	init_ability_info()
	_init_ability_timer()

func _process(delta: float) -> void:
	#physics 检查重力和摩擦力
	_check_gravity(delta)
	_check_friction(delta)
	#animation
	_update_sprite_forwad()
	#combat
	_attack_progress(delta)
	_hurt_progress(delta) 
	

func _physics_process(delta: float) -> void:
	#animation
	_update_animator_data()
	#locomotion
	move_and_slide()
#endregion
