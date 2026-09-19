extends Resource
class_name EffectUnit

enum EffectType{
	ATTACK = 0,
	DEFENCE = 1,
	MAX_HP = 2,
	HP_HEAL = 3,
}

@export var effect_id : StringName

@export var max_level : int
@export var base_duration : float

@export var eff_dir : Dictionary[EffectType,float] #类型和基本比率
