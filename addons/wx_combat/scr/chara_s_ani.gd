extends AnimationTree
class_name AnimatorBase

#暂未启用
#region SignalsHook
#传的是事件的类型
signal change_side(bool)
#endregion

#region LocomotionUpdate
var has_velocity : bool
var is_air : bool

var velocity : Vector3

var walk_speed : float = 100
var jump_speed : float = 100

#更新移动速度
func update_locomotion_data(vel) -> void:
	velocity = vel
	is_air = velocity.y != 0
	has_velocity = (velocity.x != 0 or velocity.z != 0)
	
	
	self["parameters/air_loco/blend_position"] = velocity.y / jump_speed
	
	
#endregion

#region AbilityAnimation
@onready var playback_sm :AnimationNodeStateMachinePlayback = self.get("parameters/playback")
var is_ability : bool = false  #正在能力中

func play_montage(name : String):
	if not playback_sm :
		return
	playback_sm.start(&"Ability")
	self["parameters/Ability/Transition/transition_request"] = name


var is_death : bool = false


#endregion

#region SPRITE
@export var sprite3d : AnimatedSprite3D

var vel_last_frame : Vector3 = Vector3.ZERO
var is_right : bool = true

#调整Sprite的朝向
func _sprite_forwad_update() -> void:

	#处于受伤状态就不用再改了
	if velocity.x == 0 or is_ability:
		return
	#看看两者是否不同
	
	#配置是否朝向右侧
	is_right = velocity.x > 0
	
	if vel_last_frame.x * velocity.x <= 0:
		sprite3d.flip_h = not is_right
		change_side.emit(is_right)   #发出信号，说明自己转向了
		
#endregion

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	#根据方向进行翻转
	#print(owner.name," ",is_ability)
	
	pass

func _physics_process(delta: float) -> void:
	_sprite_forwad_update()
	vel_last_frame = velocity
