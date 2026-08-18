extends Node

#region STATS
#region /BASE_PARA
@export_category("TempStats")
@export var max_hp : float 
var hp

@export var base_attack : float   #基础攻击
var attack		#当前实际攻击
@export var base_defense : float  #基础防御
var defense		#当前防御

#简单的初始化
func _init_stats() -> void:
	hp = max_hp
	attack = base_attack
	defense = base_defense
#endregion

#region /STATS_INFO 数值的某些信息

func _update_stats_info() -> void:
	#hp不能小于0
	if hp < 0:
		hp = 0

#获取攻击伤害，数值为攻击力乘上传来的比率
func get_attack_demage(rate:float) -> float:
	return (attack * rate)



#endregion


#region unused_temp
var base_speed   #基础速度
var speed		#当前速度
var base_crit_rate  #基础暴击率
var crit_rate    #当前暴击率
#endregion

func _ready() -> void:
	_init_stats()
	
