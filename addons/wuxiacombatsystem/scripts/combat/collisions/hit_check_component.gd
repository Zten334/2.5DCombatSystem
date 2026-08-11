extends Area3D


	
	
#region HITCHECK_BOX 攻击检测盒
@export var init_scale : Vector3  #测试用的初始碰撞盒scale

@onready var collision : DynamicBoxCollision = $DynamicBoxCollision
#endregion

#已经弃用
#V0.13 决定把ability的逻辑抽象至角色层，使AttackComponent的逻辑更加简洁
#region ATTACK_INFO 攻击（或者说招式）信息
#这里为了保留未来不同ability的信息区间
#我把攻击和ability给拆开了，而不是放在数组里
#也有一部分原因是只有四个，其实并不算多
#endregion

#region INIT_RESOURCE 初始化资源
#只在进入场景时执行一次，初始化攻击内容


#初始化碰撞大小
func init_collision(target_scale : Vector3) -> void:
	if not collision:
		return
	#设置碰撞盒的尺寸
	collision.set_shape_scale(target_scale)

#endregion

#region EXCUTE_ATTACKING 执行攻击效果


#检测攻击碰撞
func check_hit(attack_type : int) -> void:
	var hits = get_overlapping_bodies()
	for hit in hits:
		if hit.has_method("hurt"):
			hit.hurt(attack_type)


#endregion


func _ready() -> void:
	#初始化能力信息
	init_collision(init_scale) 

func _process(delta: float) -> void:
	pass
