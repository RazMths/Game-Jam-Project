extends Node2D

@export var video: VideoStreamPlayer

@onready var intro_sound_1: AudioStreamPlayer2D = $IntroSound1
@onready var intro_sound: AudioStreamPlayer2D = $IntroSound


func _ready() -> void:
	video.finished.connect(func(): get_tree().change_scene_to_file("res://القائمات/القائمه الرائيسيه/main_menu.tscn"))
	await get_tree().create_timer(3.1).timeout
	intro_sound_1.play()
