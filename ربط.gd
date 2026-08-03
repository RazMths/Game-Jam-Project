extends Node

@export var target_spawn: Marker2D
@export var echo_shader_rect: ColorRect
@export var player: Node2D 
@export var target_camera: Camera2D

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






func _on_area_2d_body_entered(body: Node2D) -> void:
	# التأكد من أن الكائن الذي دخل هو اللاعب وأن العناصر متوفرة
	if body == player and target_camera and echo_shader_rect:
		var mat = echo_shader_rect.material as ShaderMaterial
		
		# 1. إنشاء الحركة: تصغير الدائرة إلى 0.0 (خلال 0.4 ثانية)
		var tween = create_tween()
		tween.tween_property(mat, "shader_parameter/transition_size", 0.0, 0.4)
		
		# 2. تغيير الكاميرا ونقل اللاعب فور اكتمال تصغير الدائرة
		tween.tween_callback(func():
			target_camera.make_current()
			if target_spawn:
				player.global_position = target_spawn.global_position # 📍 هنا مكان السطر الجديد
		)
		
		# 3. تكبير الدائرة مجدداً إلى 1.0 (خلال 0.4 ثانية)
		tween.tween_property(mat, "shader_parameter/transition_size", 1.0, 0.4)
		
