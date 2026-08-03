extends Area2D

@export_category("Door Configuration")
@export var target_spawn: Marker2D        # 📍 نقطة الوصول في الغرفة الجديدة
@export var target_camera: Camera2D       # 🎥 الكاميرا الجديدة
@export var player: Node2D                # 🏃‍♂️ عقدة اللاعب (يمكن تركها فارغة إذا كان اللاعب في مجموعة "player")
@export var echo_shader_rect: ColorRect   # ⬛ غطاء الانتقال بالشادر

var _is_transitioning: bool = false
var _shader_material: ShaderMaterial

func _ready() -> void:
	set_process(false)
	
	if echo_shader_rect and echo_shader_rect.material is ShaderMaterial:
		_shader_material = echo_shader_rect.material as ShaderMaterial

	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if player and _shader_material:
		var canvas_transform = get_viewport().get_canvas_transform()
		var player_pos = canvas_transform * player.global_position
		_shader_material.set_shader_parameter("player_screen_pos", player_pos)

func _on_body_entered(body: Node2D) -> void:
	print("دخل شيء إلى الباب: ", body.name) # للتأكد من أن الباب يحس بالدخول
	
	if _is_transitioning:
		return
		
	# 1. التعرّف على اللاعب: إذا لم تحدده في الـ Inspector، نتحقق هل ينتمي لمجموعة "player"
	if player == null:
		if body.is_in_group("player") or body.name.to_lower().contains("player"):
			player = body
		else:
			print("تنبيه: الجسم ليس هو اللاعب المعرف!")
			return
	elif body != player:
		return

	_is_transitioning = true
	print("بدأت عملية الانتقال...")

	if _shader_material:
		set_process(true)
		var tween = create_tween()
		
		# إغلاق الشادر
		tween.tween_property(_shader_material, "shader_parameter/transition_size", 0.0, 0.4)
		
		# نقل اللاعب عند اكتمال الإغلاق
		tween.tween_callback(func():
			_teleport_player()
		)
		
		# فتح الشادر
		tween.tween_property(_shader_material, "shader_parameter/transition_size", 1.0, 0.4)
		
		tween.tween_callback(func():
			set_process(false)
			_is_transitioning = false
		)
	else:
		# إذا لم يوجد شادر، يتم النقل فوراً
		_teleport_player()
		_is_transitioning = false

func _teleport_player() -> void:
	if target_spawn:
		if player:
			player.global_position = target_spawn.global_position
			print("تم نقل اللاعب إلى: ", target_spawn.global_position)
		else:
			print("خطأ: لم يتم العثور على عقدة اللاعب لنقله!")
	else:
		print("خطأ: لم يتم تعيين target_spawn في الباب!")
		
	if target_camera:
		target_camera.make_current()
