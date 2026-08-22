extends CharacterBody3D
class_name CombatChara

#region BASIC 基本信息和功能
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
@export_category("Components")

var stay_air : bool = false



#region LOCOMOTIONS 人物运动
#应用重力
func _gravity_check(delta: float) -> void:
	if stay_air:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_rate

func jump_up() -> void:
	velocity.y = jump_velocity

##2D运动
#应用摩擦力
func _friction_check(delta:float) -> void:
	velocity.x = move_toward(velocity.x,0,delta * friction_strength)
	velocity.z = move_toward(velocity.z,0,delta * friction_strength)

#为当前角色施加加速度
#forward:前进的方向，任意长度，Vector2
#delta：速度增量
#暂时：攻击时不能被加速
func accel_prcs(forward,delta) -> void:
	if cur_att_phase != AttackPhase.NONE:
		return
	var new_vel = forward.normalized() * max_speed
	#这里使用的是move_toward，匀加速运动
	velocity.x = move_toward(velocity.x,new_vel.x,delta * acceleration)
	velocity.z = move_toward(velocity.z,new_vel.y,delta * acceleration)
	
	#var new_forward = Vector3(new_vel.x - velocity.x,0,new_vel.y - velocity.z)
	#new_forward = new_forward.normalized()
	#velocity += new_forward * delta * acceleration
	
#直接设置当前角色的速度
#forward:方向
#rate:与最大速率的比例
func velocity_assign(forward,rate = 1) -> void:
	velocity.x = forward.x * rate * max_speed
	velocity.z = forward.y * rate * max_speed
#endregion

#region ANIMATION 动画控制
@onready var animation_tree = $AnimationTree
@onready var sprite3d = $AnimatedSprite3D

#记录上一帧的方向，用于判断转向
var vel_last_frame : Vector3 = Vector3.ZERO
var is_right : bool = true

#调整Sprite的朝向
func _sprite_forwad_update() -> void:
	#处于受伤状态就不用再改了
	if velocity.x == 0:
		return
	#看看两者是否不同
	
	#配置是否朝向右侧
	is_right = velocity.x > 0
	
	if vel_last_frame.x * velocity.x <= 0:
		sprite3d.flip_h = not is_right
		if attack_comp:
			attack_comp.flip(is_right)
	
	
	
#更新AnimationTree中的运动相关数据
func _animator_data_update() -> void:
	if !animation_tree:
		return
	animation_tree.update_locomotion_data(velocity)

func _montage_play(_name) -> void:
	if !animation_tree or !_name:
		return
	animation_tree.play_montage(_name)
#endregion


#endregion

#region AI_CONTROLLER 提供给AI控制器的接口
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
	
	attack_comp.collision_layer = 0
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

var cur_att_phase : AttackPhase = AttackPhase.NONE #当前的攻击阶段

var attacking_speed   #测试，攻击速度修正

func _attack_init() -> void:
	if not attack_comp:
		return
	#连接碰撞检测和攻击阶段切换的信号
	attack_comp.hit_check.connect(_hit_check_excute)
	#连接范围检测的信号
	attack_comp.body_entered.connect(_body_enter_attarea)
	#连击计时器信号

#运行攻击计时器的规则
func _attack_progress(delta:float) -> void:
	if not attack_comp:
		#print(name," No Attack Component!")
		return
	#将攻击阶段与component同步,即如果不是处于攻击状态，就将攻击阶段设为NONE
	cur_att_phase = attack_comp.cur_phase
	#攻击补偿速度
	_atk_accl(delta)
	
#轻攻击（暂定），需要去招式资源组件中读取，然后根据index进行选择
func light_attack() -> void:
	#如果当前正在攻击阶段，则跳过
	if not attack_comp:
		return
	#播放动画
	var anim_name = attack_comp.attack_start()
	_montage_play(anim_name)
	
#region /TOOLFUNC 工具函数，主要是信号绑定相关的
signal body_enter_attarea(Node3D)
#切换当前攻击状态


#接收到碰撞检测信号后执行，主要可让各个component之间通信
func _hit_check_excute(attack_type:int,hits:Array) -> void:
	for hit in hits:
		if hit.has_method("hurt"):
			hit.hurt(attack_type,20,(hit.position - position))
			#stats_component.att_dmg_get(1)
	print(name," The Hit Point Is Trigger!")

#接受攻击范围检测信号后执行，意为有body进入了攻击范围
func _body_enter_attarea(body:Node3D) -> void:
	body_enter_attarea.emit(body)

func _atk_accl(delta) -> void:
	if cur_att_phase != AttackPhase.RUNNING:
		return
	
	#if is_right:
	
	var new_vel = (Vector3.RIGHT * max_speed 
	if is_right else 
	Vector3.LEFT * max_speed)
	
	#这里使用的是move_toward，匀加速运动，比率可变
	velocity.x = move_toward(0,new_vel.x,delta * acceleration * 1.3)
	velocity.z = move_toward(0,new_vel.z,delta * acceleration * 1.3)

#endregion

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
		
	#如果hurt_timer大于0，就说明正在受伤
	is_hurting = hurt_comp.is_hurting
	
	_hurt_accl(delta)
	
#匹配攻击类型,暂时用枚举
#与hurt_type是一一对应的
func hurt(attack_type:int,damage:float,dmg_dir:Vector3) -> void:
	if is_hp_zero or not hurt_comp:
		return
	#记录伤害来源方向
	hurt_dir = dmg_dir
	
	print(name," is hurt! the damage is ",damage)
	
	hp -= damage
	
	#如果正在攻击，就不会触发伤害计算，但是会扣血
	if cur_att_phase != AttackPhase.NONE:
		return
	#播放蒙太奇
	var anim_name = hurt_comp._hurt_start(attack_type)
	_montage_play(anim_name)
	
	
	

func _hurt_accl(delta) -> void:
	if not is_hurting:
		return
	
	var new_vel = hurt_dir.normalized() * max_speed
	print(new_vel)
	#这里使用的是move_toward，匀加速运动，比率可变
	velocity.x = move_toward(0,new_vel.x,delta * acceleration * 2)
	velocity.z = move_toward(0,new_vel.z,delta * acceleration * 2)

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
	_sprite_forwad_update()
	#ai
	
	

func _physics_process(delta: float) -> void:
	#physics 检查重力和摩擦力
	_gravity_check(delta)
	_friction_check(delta)
	
	
	#combat
	_attack_progress(delta)
	_hurt_progress(delta) 
	
	#animation
	_animator_data_update()
	#locomotion
	move_and_slide()
	
#endregion
