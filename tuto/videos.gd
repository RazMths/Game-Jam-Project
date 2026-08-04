extends Node2D

@export var video: VideoStreamPlayer

@onready var intro_sound_1: AudioStreamPlayer2D = $IntroSound1
@onready var intro_sound: AudioStreamPlayer2D = $IntroSound
@onready var intro_sound_2: AudioStreamPlayer2D = $IntroSound2


func _ready() -> void:
	video.play()
	video.finished.connect(func(): get_tree().change_scene_to_file("res://القائمات/القائمه الرائيسيه/main_menu.tscn"))
	_for_just_play_good_sound()
	await get_tree().create_timer(3.1).timeout
	intro_sound_1.play()

func _for_just_play_good_sound():
	await get_tree().create_timer(1.15).timeout
	intro_sound_2.play()
