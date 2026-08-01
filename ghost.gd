extends Area2D

@export_category("Enemy Movement")
@export var SPEED: float = 60.0
@export var MOVE_DISTANCE: float = 120.0 

@export_category("Willpower Rewards & Penalties")
@export var WILLPOWER_REWARD: float = 12.0 
@export var CONTACT_PENALTY: float = 10.0  

@export_category("Burst Effect Settings")
@export var BURST_PIECES_COUNT: int = 8  # عدد الشظايا/الصور المتناثرة بالانفجار
@export var BURST_RADIUS: float = 80.0    # مدى مسافة تناثر الصور
@export var BURST_DURATION: float = 0.35  # سرعة اختفاء وتناثر الانفجار

var start_x: float = 0.0
var direction: int = 1
var fade_tween: Tween
var duration: float = 1.4

@onready var sprite = $Sprite # أو Sprite2D

func _ready() -> void:
	start_x = global_position.x
	body_entered.connect(_on_body_entered)
	
	# for fading effect
	sprite.modulate.a = 0.0

func _physics_process(delta: float) -> void:
	global_position.x += SPEED * direction * delta
	
	if abs(global_position.x - start_x) >= MOVE_DISTANCE:
		direction *= -1
		if sprite:
			sprite.flip_h = (direction < 0)

func _on_body_entered(body: Node) -> void:
	if body.name == "Player" or body.has_method("add_fear_time"):
		if "is_dashing" in body and body.is_dashing:
			# --- مكافأة الإرادة ---
			body.add_fear_time(WILLPOWER_REWARD)
			
			if "dash_impact_shake" in body:
				body.dash_impact_shake = 9.0
				
			if body.has_method("spawn_echo"):
				body.spawn_echo(220.0)
				
			# إطلاق تأثير الانفجار للشبح
			spawn_ghost_burst()
		else:
			# --- عقوبة لمس الشبح بدون داش ---
			if body.has_method("add_fear_time"):
				body.add_fear_time(-CONTACT_PENALTY)
				
			if "velocity" in body:
				var push_dir = 1.0 if body.global_position.x > global_position.x else -1.0
				body.velocity.x = push_dir * 350.0
				body.velocity.y = -150.0

# --- دالة انفجار صورة الشبح لملايين القطع الشفافة ---
func spawn_ghost_burst() -> void:
	# 1. إخفاء الشبح الاصلي وتعطيل تصادمه فوراً
	monitoring = false
	if sprite:
		sprite.visible = false

	# الحصول على الملمس الحالي (Texture) للشبح
	var current_texture: Texture2D = null
	if sprite is AnimatedSprite2D:
		current_texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	elif sprite is Sprite2D:
		current_texture = sprite.texture

	# 2. إنشاء شظايا صور متحركة متناثرة دائرياً
	for i in range(BURST_PIECES_COUNT):
		var piece = Sprite2D.new()
		piece.texture = current_texture
		piece.global_position = global_position
		piece.scale = sprite.scale if sprite else Vector2.ONE
		piece.flip_h = sprite.flip_h if sprite else false
		
		# جعل لون الشظايا خفيفاً مضيئاً وشبه شفاف
		piece.modulate = Color(2.0, 1.2, 1.2, 0.8) # إعطاؤها لون أحمر/مضيء خفيف
		
		# إضافة الشظية للمشهد الأساسي
		get_tree().current_scene.add_child(piece)
		
		# حساب اتجاه وزاوية طيران هذه القطعة (توزيع دائري كامل)
		var angle = (TAU / BURST_PIECES_COUNT) * i + randf_range(-0.2, 0.2)
		var target_offset = Vector2.UP.rotated(angle) * randf_range(BURST_RADIUS * 0.7, BURST_RADIUS * 1.3)
		var target_pos = global_position + target_offset
		
		# تحريك وتلاشي وتكبير الشظية ناعماً بواسطة Tween
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# طيران للشعار الخارجي
		tween.tween_property(piece, "global_position", target_pos, BURST_DURATION)
		# اختفاء التدريجي للشفافية
		tween.tween_property(piece, "modulate:a", 0.0, BURST_DURATION)
		# تكبير حجم الصورة أثناء التناثر لتبيّن كأنها موجة انفجارية
		tween.tween_property(piece, "scale", piece.scale * 1.6, BURST_DURATION)
		# دوران خفيف للشظايا
		tween.tween_property(piece, "rotation", randf_range(-PI, PI), BURST_DURATION)
		
		# حذف القطعة من الذاكرة فور انتهاء التأثير
		tween.finished.connect(piece.queue_free)

	# 3. حذف عقدة الشبح الأصلية بعد اكتمال زمن الانفجار
	get_tree().create_timer(BURST_DURATION).timeout.connect(queue_free)


func reveal_platform() -> void:
	# إذا كان هناك تأثير تلاشي شغال حالياً، نلغيه ونبدأ من جديد
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	# 1. إظهار المنصة فوراً
	sprite.modulate.a = 1.0
	
	# 2. عمل تلاشي تدريجي (Fade out) خلال ثانيتين مثلاً
	fade_tween = create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, duration)
