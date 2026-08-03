extends Area2D

@export_category("Door Configuration")
@export var target_spawn: Marker2D       # 📍 نقطة الوصول في الغرفة الجديدة
@export var target_camera: Camera2D      # 🎥 الكاميرا الجديدة
@export var player: Node2D               # 🏃‍♂️ عقدة اللاعب
@export var echo_shader_rect: ColorRect  # ⬛ غطاء الانتقال بالشادر

func _ready() -> void:
	# ربط إشارة دخول الباب تلقائياً
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	# تحديث موقع اللاعب داخل الشادر استناداً لشاشة العرض
	if player and echo_shader_rect and echo_shader_rect.material:
		var mat = echo_shader_rect.material as ShaderMaterial
		var canvas_transform = get_viewport().get_canvas_transform()
		var player_pos = canvas_transform * player.global_position
		mat.set_shader_parameter("player_screen_pos", player_pos)

func _on_body_entered(body: Node2D) -> void:
	# التأكد من أن الذي دخل هو اللاعب فعلاً
	if body == player:
		if echo_shader_rect and echo_shader_rect.material:
			var mat = echo_shader_rect.material as ShaderMaterial
			
			# 1. إغلاق الشادر (تصغير الشاشة إلى 0.0 خلال 0.4 ثانية)
			var tween = create_tween()
			tween.tween_property(mat, "shader_parameter/transition_size", 0.0, 0.4)
			
			# 2. نقل اللاعب وتغيير الكاميرا في اللحظة المظلمة
			tween.tween_callback(func():
				if target_camera:
					target_camera.make_current()
				if target_spawn:
					player.global_position = target_spawn.global_position
			)
			
			# 3. فتح الشادر مجدداً (تكبير الشاشة إلى 1.0)
			tween.tween_property(mat, "shader_parameter/transition_size", 1.0, 0.4)
		else:
			# نقل مباشر في حال عدم استخدام الشادر
			if target_camera:
				target_camera.make_current()
			if target_spawn:
				player.global_position = target_spawn.global_position
