extends Control

@export var timer: float = 1.4

var t = 0 
func _process(delta: float) -> void:
	t += delta
	if t > timer:
		get_tree().change_scene_to_file("res://tuto/after_start.tscn")
