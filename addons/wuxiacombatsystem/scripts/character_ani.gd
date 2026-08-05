extends AnimationTree
#class_name CharacterAnimator

#暂未启用
#region SignalsHook
#传的是事件的类型
signal trigger_event(int)

signal dir_event(int,Vector3)

func envoke_trigger_event(tag : StringName,vector:Vector3 = Vector3.ZERO) -> void:
	pass
#endregion

#region LocomotionUpdate
var velocity : Vector3
var has_velocity : bool

#更新移动速度
func update_locomotion_data(vel) -> void:
	velocity = vel
	has_velocity = (velocity != Vector3.ZERO)

#endregion

#region AbilityAnimation
@onready var playback_sm :AnimationNodeStateMachinePlayback = self.get("parameters/playback")

func play_montage(name : StringName):
	if not playback_sm :
		return
	playback_sm.start(&"Ability")
	self["parameters/Ability/Transition/transition_request"] = name

func is_right() -> bool:
	return false

#endregion

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	#简单的根据方向进行翻转
	pass
