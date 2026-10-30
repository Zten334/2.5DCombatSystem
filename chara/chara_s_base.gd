extends CharacterBody3D
class_name CombatChara

#region BASIC 基本信息和功能
@export_category("FanctionInfo")#阵营信息
@export_enum("HERO:1","ENEMY:2","NONE:3") var faction : int

@export_category("PhyscisParaData")
#越大下落得越快
@export var gravity_rate : float = 1
@export var friction_strength : float = 15
@export_category("CharacterNormalData")
@export var max_speed : float = 3
@export var acceleration : float = 30
@export var jump_velocity : float = 3

var stay_air : bool = false
var is_air : bool = false


#region LOCOMOTIONS 人物运动
@export var up_velocity : float :
	set(value):
		up_velocity = value
		velocity.y = up_velocity


#检查重力与摩擦力
func _physics_check(delta: float) -> void:
	#应用重力
	var _gravity_check = func(delta: float) -> void:
		if stay_air:
			return
		if not is_on_floor():
			var gravity_dir = get_gravity() * gravity_rate
			if velocity.y > 0:
				velocity +=  delta * gravity_dir
			else:
				velocity += delta * gravity_dir * 1.3
			
	#应用摩擦力
	var _friction_check = func(delta:float) -> void:
		velocity.x = move_toward(velocity.x,0,delta * friction_strength)
		velocity.z = move_toward(velocity.z,0,delta * friction_strength)
	
	_gravity_check.call(delta)
	_friction_check.call(delta)

func jump_up() -> void:
	if not is_on_floor():
		return
	velocity.y = jump_velocity

#为当前角色施加加速度
#forward:前进的方向，任意长度，Vector2
#delta：速度增量
#暂时：攻击时不能被加速
func accel_prcs(forward,delta) -> void:
	if attack_comp.cur_phase != AttackPhase.NONE:
		return
	var new_vel = forward.normalized() * max_speed
	#这里使用的是move_toward，匀加速运动
	velocity.x = move_toward(velocity.x,new_vel.x,delta * acceleration)
	velocity.z = move_toward(velocity.z,new_vel.y,delta * acceleration)
	
#直接设置当前角色的速度
#forward:方向
#rate:与最大速率的比例
func velocity_assign(forward,rate = 1) -> void:
	velocity.x = forward.x * rate * max_speed
	velocity.z = forward.y * rate * max_speed
#endregion

#region ANIMATION 动画控制
@export var animation_tree : AnimatorBase

func _animator_init() -> void:
	if not animation_tree:
		return
	animation_tree.jump_speed = jump_velocity
	animation_tree.walk_speed = max_speed

#更新AnimationTree中的运动相关数据
func _animator_data_update() -> void:
	if !animation_tree:
		return
		
	if is_hurting or attack_comp.cur_phase != AttackPhase.NONE:
		animation_tree.is_ability = true
	else:
		animation_tree.is_ability = false
		
	animation_tree.update_locomotion_data(velocity)
	

func _montage_play(_name) -> void:
	if !animation_tree or !_name:
		return
	animation_tree.play_montage(_name)
#endregion


#endregion

#region CONTROLLER 控制器：判断是由玩家操控还是AI操控
var is_ctring : bool #是否正在被控制


#设置当前的要追踪的实体
func is_ctring_set(value:bool) : is_ctring = value


func _ai_progress(delta:float) -> void:
	pass
#endregion

#region STATS 数值系统
@onready var stats_component = $CStats

signal death #死亡时发出的信号
signal hp_chg(float)

#region PARA 参数
@export_category("Stats")
@export var max_hp : float = 100
#做一个钳制，然后把信号发出去
var hp : float :
	set(value):
		hp = clampf(value,0,max_hp)
		hp_chg.emit(value)
		
@export var base_attack : float = 20  #基础攻击
var attack    #当前实际攻击
		
@export var base_defense : float = 10 #基础防御
var defense   #当前防御

@export var max_inner : float = 100   #最大内力
var inner    #当前内力

@export var max_stamina : float = 100 #最大精力
var stamina  #当前精力


#endregion

var is_hp_zero : bool = false #标志位，供其他组件判断hp是否为0了

#简单的初始化
func _stats_init() -> void:
	hp = max_hp
	attack = base_attack
	defense = base_defense

func _stats_info_update() -> void:
	if hp == 0 and not is_hp_zero:
		is_hp_zero = true
		death.emit()
		#设置动画
		animation_tree.is_death = true
		
		print(name," is dead!")


func hp_get() -> float: return hp
	
func max_hp_get() -> float: return max_hp

#endregion

#region COMBAT 战斗系统
@export_category('Comps')

#region /FACTION 阵营
func _faction_collision_init() -> void:
	collision_layer = faction
	
	match faction:
		1:
			set_collision_mask_value(1,false)
			set_collision_mask_value(2,true)
		2:
			set_collision_mask_value(1,true)
			set_collision_mask_value(2,false)
			
	set_collision_mask_value(6,true) #统一和block层碰撞
	
	if not attack_comp:
		return
	
	attack_comp.collision_layer = faction
	#attack_comp.init_collision
	match faction:
		1:
			attack_comp.set_collision_mask_value(1,false)
			attack_comp.set_collision_mask_value(2,true)
		2:
			attack_comp.set_collision_mask_value(1,true)
			attack_comp.set_collision_mask_value(2,false)
	
#endregion

#region /ATTACK 攻击
@export var attack_comp : AttackComp

const AttackPhase = AttackComp.AttackPhase

var attacking_speed   #测试，攻击速度修正

func _attack_init() -> void:
	if not attack_comp:
		return
	#连接碰撞检测和攻击阶段切换的信号
	attack_comp.swith_phase.connect(_atk_phase_switch)
	attack_comp.hit_check.connect(_hit_check)
	#attack_comp.cross_check.connect(_cross_check_excute)
	#连接范围检测的信号
	attack_comp.body_entered.connect(_body_enter_attarea)
	#连击计时器信号
	#动画的信号和攻击组件的换边绑定
	if not animation_tree:
		return
	animation_tree.change_side.connect(attack_comp.flip)

#运行攻击计时器的规则
func _attack_progress(delta:float) -> void:
	if not attack_comp:
		#print(name," No Attack Component!")
		return
	#攻击时的加速
	var _atk_accl =  func(delta) -> void:
		if attack_comp.cur_phase == AttackPhase.NONE:
			return
		
		#这里使用的是move_toward，匀加速运动，比率可变
		velocity.x = move_toward(velocity.x,0,delta * acceleration * 2)
		velocity.z = move_toward(velocity.z,0,delta * acceleration * 2)
	
	#将攻击阶段与component同步,即如果不是处于攻击状态，就将攻击阶段设为NONE
	attack_comp.cur_phase = attack_comp.cur_phase
	#攻击补偿速度
	_atk_accl.call(delta)


#轻攻击（暂定），需要去招式资源组件中读取，然后根据index进行选择
func light_attack() -> void:
	#如果当前正在攻击阶段，则跳过
	if not attack_comp:
		return
	#播放动画
	var anim_name = attack_comp.attack_start()
	_montage_play(anim_name)

func _atk_phase_switch(phase : int) -> void:
	match phase:
		AttackPhase.FRONT:
			pass
		AttackPhase.RUNNING:
			var new_vel = (Vector3.RIGHT * max_speed 
			if animation_tree.is_right else 
			Vector3.LEFT * max_speed)
			
			velocity.x = new_vel.x
			velocity.z = new_vel.z
			
		AttackPhase.REST:
			pass


#endregion

#region /CROSS 交锋 暂时不用

#endregion

#region /TOOLFUNC 工具函数，主要是信号绑定相关的
signal body_enter_attarea(Node3D)
#切换当前攻击状态

#这里后续需要一个managerment来管理一下比较好
#接收到碰撞检测信号后执行，主要可让各个component之间通信
func _hit_check(attack_type:int,hits:Array) -> void:
	#用一个内置函数
	var _hit_excute = func(attack_type: int,hit : CombatChara) -> void:
		if hit.attack_comp and hit.hurt_comp:
			
			#先执行受击函数
			hit.hurt(attack_type,20,(hit.position - position)) 
			
			#判断是否处于交锋
			if (attack_comp.overlaps_area(hit.attack_comp) and
			hit.attack_comp.check_cross()):
			#这里可以进一步判断，目前就各打50大板
				print(name,' And ',hit.name,' Has Crossed!')
				hurt(attack_type,20,( position - hit.position))
				 #触发交锋
			else:
				#执行受击计时
				var anim_name = hit.hurt_comp._hurt_start(attack_type)
				#播放蒙太奇
				hit._montage_play(anim_name)
				#触发受击
	
	for hit in hits:
		if hit is CombatChara:
			_hit_excute.call(attack_type,hit)
	print(name," The Hit Point Is Trigger!")

	

#接受攻击范围检测信号后执行，意为有body进入了攻击范围
func _body_enter_attarea(body:Node3D) -> void:
	body_enter_attarea.emit(body)



#endregion

#region /SKILL 技能





#endregion


#region /HURT 受伤

@export var hurt_comp : HurtComp

const HurtType = HurtComp.HurtType

var current_hurt_type : HurtType 

var is_hurting : bool = false
var hurt_dir : Vector3 

func _hurt_progress(delta:float) -> void:
	if not hurt_comp:
		return
	
	var _hurt_accl = func(delta) -> void:
		if not is_hurting or attack_comp.cur_phase != AttackPhase.NONE:
			return
		##这里使用的是move_toward，匀加速运动，比率可变
		velocity.x = move_toward(velocity.x,0,delta * acceleration * 1)
		velocity.z = move_toward(velocity.z,0,delta * acceleration * 1)
	#如果hurt_timer大于0，就说明正在受伤
	is_hurting = hurt_comp.is_hurting
	
	_hurt_accl.call(delta)
	
#匹配攻击类型,暂时用枚举
#与hurt_type是一一对应的
func hurt(attack_type:int,damage:float,dmg_dir:Vector3) -> void:
	if is_hp_zero or not hurt_comp:
		return
	#记录伤害来源方向，并配置速度冲量
	hurt_dir = dmg_dir
	var new_vel = hurt_dir.normalized() * max_speed
	velocity.x = new_vel.x
	velocity.z = new_vel.z
	
	print(name," is hurt! the damage is ",damage)
	
	hp -= damage


#endregion


#endregion

#region CLASK_FUNC 自带的钩子函数
func _ready() -> void:
	_attack_init()
	_faction_collision_init()
	_stats_init()

func _process(delta: float) -> void:
	#stats 处理数值相关的逻辑，第一优先
	_stats_info_update()
	#animation
	#ai
	
	

func _physics_process(delta: float) -> void:
	#print(name,' ',is_hurting,' ',velocity)
	#physics 检查重力和摩擦力
	
	_physics_check(delta)
	
	
	#combat
	_attack_progress(delta)
	_hurt_progress(delta) 
	
	#animation
	_animator_data_update()
	#locomotion
	move_and_slide()
	
#endregion
