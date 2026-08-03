extends Area2D


func _ready() -> void:
	body_entered.connect(func(v):
		get_tree().change_scene_to_file("res://tuto/last_video.tscn")
)
