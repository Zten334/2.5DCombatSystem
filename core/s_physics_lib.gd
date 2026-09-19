extends Object
class_name Physics_Lib


static func _pos_bias_to_loco(cur_pos,last_pos,delta) -> Vector3:
	return (cur_pos - last_pos)/delta




#class Pos_To_Vel:
	#
	#var last_pos : Vector3
	#
	#func _pos_bias_to_loco(cur_pos,delta) -> Vector3:
		#var vel = (cur_pos - last_pos)/delta
		#last_pos = cur_pos
		#return vel
