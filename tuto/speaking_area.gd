extends Area2D

@onready var sp_audio: AudioStreamPlayer2D = $"sp audio"
var bd
var played = false

func _ready() -> void:
	body_entered.connect(func(bds):
		if not played:
			played = true
			sp_audio.play()
			bd = bds
		)
	sp_audio.finished.connect(func():
		get_tree().change_scene_to_file("res://main.tscn")
	)
