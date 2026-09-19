extends Node

#region STATS
#region /BASE_PARA
@export_category("TempStats")
@export var max_hp : float = 100
#做一个钳制
var hp :
	set(value):
		hp = clamp(value,0,max_hp)

@export var base_attack : float = 20  #基础攻击
var attack    #当前实际攻击
		
@export var base_defense : float = 10 #基础防御
var defense   #当前防御

#简单的初始化
func _init_stats() -> void:
	hp = max_hp
	attack = base_attack
	defense = base_defense
#endregion

#region /STATS_INFO 数值的某些信息

func _update_stats_info() -> void:
	pass

#获取攻击伤害，数值为攻击力乘上传来的比率
func att_dmg_get(rate:float) -> float:
	return (attack * rate)

#endregion

#region /UI UI更新
func _ui_update(delta:float) -> void:
	pass

#endregion
#endregion



#region BUFF buff系统
enum EffectType{
	STUN = 0,
	HEAL = 1,
	AIR = 2,
	WEAK = 3,
}

class EffectInfo :
	var left_time : float  #剩余时间
	var layer : int       #层数


var buff_dir : Dictionary[EffectType,EffectInfo]






#endregion

func _ready() -> void:
	_init_stats()
	
