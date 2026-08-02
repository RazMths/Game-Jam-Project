extends Control

const MAIN = preload("uid://chunypk5a35q8")

@export var timer: float = 1.4

var t = 0 
func _process(delta: float) -> void:
	t += delta
	if t > timer:
		get_tree().change_scene_to_file("res://main.tscn")
