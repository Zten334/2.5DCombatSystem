extends Node3D

@export var bgm : AudioStream



func _ready() -> void:
	SoundManager.play_bgm(bgm)
	
