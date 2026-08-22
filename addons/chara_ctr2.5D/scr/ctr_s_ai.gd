extends Area3D

#region CONTROLLING 控制
@export var owning_chara : CombatChara

var chara_pos : Vector3

#朝最近的那个目标移动
func move_to_nearest(delta) -> bool:
	var distan_x =  nearest_ent.position.x - chara_pos.x
	var distan_z = nearest_ent.position.z - chara_pos.z
	
	#x轴方向到了一定程度就不用继续了
	if abs(distan_x) <= 0.5:
		distan_x = 0
	if abs(distan_z) <= 0.2:
		distan_z = 0
		
	var forward = Vector2(distan_x,distan_z)
	
	#进行加速
	owning_chara.accel_prcs(forward,delta)
	#如果forward为0，说明已经到达
	return forward == Vector2.ZERO
#endregion

#region SENSE 感知
@export var max_sense_num : int = 3

var entities_within : Dictionary[Node3D,float]

var nearest_ent : Node3D 

@export var sense_intvel : float = 0.5

var sense_timer : float

func _sense_init() -> void:
	#连接area的信号
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	#重启sense_timer
	sense_timer = sense_intvel

func _refresh_ent_distan() -> void:
	var entities = entities_within.keys()
	#刷新一遍视野中所有body与当前的距离
	if not entities:
		nearest_ent = null
		return
	nearest_ent = entities.pick_random()
	for ent in entities:
		entities_within[ent] = chara_pos.distance_squared_to(ent.position)
		#如果有新的实体位置比当前最近的小，就更新实体信息
		if entities_within[ent] < chara_pos.distance_squared_to(nearest_ent.position):
			nearest_ent = ent

func _on_body_enter(body:Node3D) -> void:
	#如果实体字典已经装满了，就不再执行
	if len(entities_within.keys()) > max_sense_num:
		return
	#print(body.name,' Is Enter!')
	entities_within[body] = chara_pos.distance_squared_to(body.position)
	
#当body离开范围的时候判断
#如果存在字典中，就擦除
func _on_body_exit(body:Node3D) -> void:
	if entities_within.has(body):
		entities_within.erase(body)
	#print(body.name,' Is Leave!')

func _hp_chg(value:float) -> void:
	pass
	
func _chara_death() -> void:
	owning_chara = null
#endregion

#region STRATEGY 策略
enum AI_Strategy{
	NONE,
	SEARCH,
	FIGHT,
}
@export var strate_label : Label3D
var cur_strategy : AI_Strategy = AI_Strategy.SEARCH
#region SEARCH 搜索
@export var alter_dur_max : float  = 1#最大警觉时间
var alter_timer : float = 0



#endregion

func _strategy_switch() -> void:
	match cur_strategy:
		AI_Strategy.SEARCH:
			if alter_timer == alter_dur_max:
				cur_strategy = AI_Strategy.FIGHT
				alter_timer = 0
		AI_Strategy.FIGHT:
			if not nearest_ent:
				cur_strategy = AI_Strategy.SEARCH

#操控角色时所使用的策略过程
func _control_progress(delta:float) -> void:
	match cur_strategy:
		AI_Strategy.SEARCH:
			if not nearest_ent:
				alter_timer -= delta
			else:
				alter_timer += delta
			alter_timer = clampf(alter_timer,0,alter_dur_max)
		AI_Strategy.FIGHT:
			if not nearest_ent:
				return
			move_to_nearest(delta)
	#如果还没有达到指定目标，便超目标方向移动


func _attack(body:Node3D) -> void:
	if not owning_chara or cur_strategy != AI_Strategy.FIGHT:
		return
	
	
	#节省内存
	if owning_chara.has_method("light_attack"):
		print(name,' decide to attack!')
		owning_chara.light_attack()
	
#endregion

func _ui_update() -> void:
	pass

func _ready() -> void:

	_sense_init()
		#character init
	if not owning_chara:
		return
		
	owning_chara.body_enter_attarea.connect(_attack)
	owning_chara.hp_chg.connect(_hp_chg)
	owning_chara.death.connect(_chara_death)
	
func _process(delta: float) -> void:
	if not owning_chara:
		return
	
	_ui_update()
	
	#切换状态
	_strategy_switch()

func _physics_process(delta: float) -> void:
	if not owning_chara:
		return
	#控制角色
	_control_progress(delta)
	#进行感知计时，固定间隔刷新最近的敌人
	sense_timer -= delta
	if sense_timer <= 0:
		_refresh_ent_distan()
		sense_timer = sense_intvel
	#设置ui
	#提取一下值，方便使用
	chara_pos = owning_chara.position
