extends CollisionShape3D

class_name DynamicBoxCollision
#这里每次都new一个新的，不要导出
var collision 


func _ready() -> void:
	collision = BoxShape3D.new()
	shape = collision

func set_shape_scale(scale : Vector3) -> void:
	collision.size = scale
