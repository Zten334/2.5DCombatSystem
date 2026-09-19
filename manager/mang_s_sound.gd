extends Node


var bgm_players : AudioStreamPlayer
var sfx_players : AudioStreamPlayer



func _ready() -> void:
	bgm_players = AudioStreamPlayer.new()
	add_child(bgm_players)
	sfx_players = AudioStreamPlayer.new()
	add_child(sfx_players)
	bgm_players.bus = 'Master'
	sfx_players.bus = 'SFX'


func _process(delta: float) -> void:
	pass

func play_bgm(audio : AudioStream) -> void:
	bgm_players.stream = audio
	bgm_players.play()



func play_sfx(audio : AudioStream) -> void:
	sfx_players.stream = audio
	sfx_players.play(0.06)
