extends Area2D

@export var time_to_add: float = 15.0 # الثواني التي يزيدها المصباح/الشرارة
@onready var pu_audio: AudioStreamPlayer2D = $"pu audio"
@onready var sprite_2d: Sprite2D = $Sprite2D

# تحميل صورة شظية الزجاج الزرقاء
var fragment_texture: Texture2D = preload("res://word/تكتشر/اساس/glass fragmet.png") 

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if is_collected:
		return
		
	if body.has_method("add_fear_time"):
		is_collected = true
		
		# 1. تشغيل الصوت في المشهد
		if pu_audio:
			var sd = pu_audio.duplicate() as AudioStreamPlayer2D
			get_tree().current_scene.add_child(sd)
			sd.global_position = global_position
			sd.play()
			sd.finished.connect(sd.queue_free)
		
		# 2. إضافة الوقت للاعب
		body.add_fear_time(time_to_add)
		
		# 3. إطلاق موجة صدى
		if body.has_method("spawn_echo"):
			body.spawn_echo(200.0)
		
		# 4. تشغيل أنميشن الانفجار بشظايا الزجاج
		_play_glass_break_effect()

# دالة إنشاء أنميشن تحطم الزجاج والتطاير
func _play_glass_break_effect() -> void:
	monitoring = false
	
	# أ) إنشاء نظام جزيئات الشظايا
	var particles = GPUParticles2D.new()
	particles.texture = fragment_texture # تعيين صورة الشظية كقوام للجزيئات
	
	var mat = ParticleProcessMaterial.new()
	
	# انتشار الشظايا بالكامل 360 درجة
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 6.0
	mat.direction = Vector3(0, 0, 0)
	mat.spread = 180.0
	
	# حركة الشظايا والاندفاع
	mat.gravity = Vector3(0, 180, 0) # جاذبية تخلي الشظايا تسقط بعد الانفجار
	mat.initial_velocity_min = 150.0
	mat.initial_velocity_max = 280.0
	
	# دوران عشوائي لشظايا الزجاج أثناء الطيران
	mat.angular_velocity_min = -360.0
	mat.angular_velocity_max = 360.0
	
	# أحجام متعدّدة للشظايا (صغيرة وكبيرة)
	mat.scale_min = 0.04
	mat.scale_max = 0.08
	
	# الشفافية والتلاشي التدريجي قبل الاختفاء
	mat.color = Color(0.5, 0.5, 0.5, 1.0) # نحافظ على ألوان الصورة الأصلية
	
	particles.process_material = mat
	particles.amount = 12 # عدد الشظايا المتطايرة
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 0.95
	
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.restart()

	# ب) أنميشن اختفاء القارورة الأساسية فوراً مع الانفجار
	if sprite_2d:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sprite_2d, "scale", sprite_2d.scale * 1.3, 0.08)
		tween.tween_property(sprite_2d, "modulate:a", 0.0, 0.1)

	# ج) التنظيف بعد اكتمال تطاير الشظايا
	await get_tree().create_timer(0.65).timeout
	particles.queue_free()
	queue_free()
