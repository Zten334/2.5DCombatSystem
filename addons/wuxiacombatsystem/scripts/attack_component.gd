extends Area3D

@export var init_scale : Vector3

@onready var collision : DynamicBoxCollision = $DynamicBoxCollision

func _ready() -> void:
	init_collision(init_scale) 

func _process(delta: float) -> void:
	pass

#region EXCUTE_ATTACKING
#初始化碰撞大小
func init_collision(target_scale : Vector3) -> void:
	if not collision:
		return
	#设置碰撞盒的尺寸
	collision.set_shape_scale(target_scale)

func excute_attack(skill_name : StringName)-> void:
	pass

#检测攻击碰撞
func check_hit() -> void:
	var hits = get_overlapping_bodies()
	for hit in hits:
		if hit.has_method("hurt"):
			hit.hurt()


#endregion
