extends Node2D

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer


func _ready() -> void:
	video_stream_player.finished.connect(func():
		get_tree().change_scene_to_file("res://tuto/tutroial_scene.tscn")
		)
