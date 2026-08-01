extends Node

@export var echo_shader_rect: ColorRect
@export var player: Node2D 

var active_waves: Array = []

func _process(_delta: float) -> void:
	if not echo_shader_rect or not echo_shader_rect.material:
		return
		
	var mat = echo_shader_rect.material as ShaderMaterial
	var canvas_transform = get_viewport().get_canvas_transform()
	
	# 1. تحديث موقع اللاعب
	if player:
		var player_pos = canvas_transform * player.global_position
		mat.set_shader_parameter("player_screen_pos", player_pos)
