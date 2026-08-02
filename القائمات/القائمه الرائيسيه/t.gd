extends Sprite2D

@export_group("Pendant Sway Dynamics")
@export var follow_speed: float = 12.0       # سرعة لحاق الشخصية بالماوس (كل ما زادت بتقل المرونة)
@export var max_tilt_angle: float = 25.0      # أقصى زاوية انحناء/تطعج (بالدرجات)
@export var tilt_responsiveness: float = 0.05  # مدى استجابة الانحناء لسرعة الفأرة
@export var return_smoothness: float = 8.0     # سرعة العودة للوضع الطبيعي

@export_group("Dash / Trail Settings")
@export var dash_speed_threshold: float = 1200.0 # السرعة المطلوبة لتفعيل الـ Dash تلقائياً
@export var trail_scene: PackedScene              # المشهد الخاص بطيف الـ Trail (Ghost)
@export var trail_spawn_interval: float = 0.04    # الزمن بين كل طيف والآخر

var last_mouse_pos: Vector2 = Vector2.ZERO
var mouse_velocity: Vector2 = Vector2.ZERO
var trail_timer: float = 0.0

func _ready() -> void:
	last_mouse_pos = get_global_mouse_position()
	global_position = last_mouse_pos

func _process(delta: float) -> void:
	var current_mouse_pos = get_global_mouse_position()
	
	# 1. حساب سرعة الفأرة المتجهة (Velocity)
	mouse_velocity = (current_mouse_pos - last_mouse_pos) / delta
	last_mouse_pos = current_mouse_pos

	# 2. تحريك الشخصية لتلحق الماوس بنعومة (Smooth Follow / Inertia)
	global_position = global_position.lerp(current_mouse_pos, follow_speed * delta)

	# 3. حساب تأثير الميدالية (التطعج والدوران بناءً على الحركة الأفقية)
	# إذا تحركت لليمين تلتف/تتطعج للجهة المقابلة أو مع اتجاه الحركة
	var target_rotation = clamp(mouse_velocity.x * tilt_responsiveness, -max_tilt_angle, max_tilt_angle)
	rotation_degrees = lerp(rotation_degrees, target_rotation, return_smoothness * delta)

	# 4. إطلاق تأثير الـ Dash / Trail عند التحريك السريع جداً
	_handle_dash_trail(delta)

func _handle_dash_trail(delta: float) -> void:
	# إذا تجاوزت سرعة الماوس الحد المطلوب يتم إنشاء أطياف الـ Dash
	if mouse_velocity.length() >= dash_speed_threshold:
		trail_timer += delta
		if trail_timer >= trail_spawn_interval:
			trail_timer = 0.0
			_spawn_trail_ghost()
	else:
		trail_timer = 0.0

func _spawn_trail_ghost() -> void:
	if not trail_scene:
		return
		
	# إنشاء نسخة من طيف الشخصية في مكانها الحالي
	var ghost = trail_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(ghost)
	
	ghost.global_position = global_position
	ghost.rotation = rotation
	ghost.scale = scale
	
	# إعطاء الطيف نفس هيئة الشخصية (Sprite2D) إذا كانت موجودة
	var my_sprite = $Sprite2D # تأكد من اسم عقدة الـ Sprite عندك
	var ghost_sprite = ghost.get_node_or_null("Sprite2D")
	if my_sprite and ghost_sprite:
		ghost_sprite.texture = my_sprite.texture
		ghost_sprite.flip_h = my_sprite.flip_h
