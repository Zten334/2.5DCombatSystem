extends Area3D

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
	
	
#region HITCHECK_BOX 攻击检测盒
@export var init_scale : Vector3  #测试用的初始碰撞盒scale

@onready var collision : DynamicBoxCollision = $DynamicBoxCollision
#endregion

#region ATTACK_INFO 攻击（或者说招式）信息
#这里为了保留未来不同ability的信息区间
#我把攻击和ability给拆开了，而不是放在数组里
#也有一部分原因是只有四个，其实并不算多

#V0.13 决定把ability的逻辑抽象至角色层，使AttackComponent的逻辑更加简洁
var attack_info : Array[AbilityInfo] #普通攻击的所有派生数组

var attack_index : int #普通攻击当前的派生顺序


#endregion

#region INIT_RESOURCE 初始化资源
#只在进入场景时执行一次，初始化攻击内容
func init_ability_info(resource) -> void:
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
	
	

#初始化碰撞大小
func init_collision(target_scale : Vector3) -> void:
	if not collision:
		return
	#设置碰撞盒的尺寸
	collision.set_shape_scale(target_scale)

#endregion

#region EXCUTE_ATTACKING 执行攻击效果

#选取攻击的类型,返回相应的攻击信息，让character处理
#1.普通攻击
#2.能力一
#3.能力二
#4.能力三
func excute_attack()-> AbilityInfo:
	return attack_info[0]

#检测攻击碰撞
func check_hit(ability_index : int,hit_check_point:int) -> void:
	var hits = get_overlapping_bodies()
	for hit in hits:
		if hit.has_method("hurt"):
			hit.hurt(attack_info[0].hit_attack_types[hit_check_point])


#endregion


func _ready() -> void:
	#初始化能力信息
	init_ability_info(1)	
	init_collision(init_scale) 

func _process(delta: float) -> void:
	pass
