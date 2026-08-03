extends CharacterBody2D

# --- الثوابت والإعدادات الأساسية ---
@export_category("Movement Settings")
@export var SPEED = 280.0            
@export var JUMP_VELOCITY = -380.0  
@export var GRAVITY = 850.0         
@export var ACCELERATION = 2400.0   
@export var DECELERATION = 2800.0   

# --- إعدادات الإضاءة التفاعلية ---
@export_category("Dynamic Light")
@export var IDLE_LIGHT_SCALE: float = 1.0   # حجم النور وأنت واقف
@export var WALK_LIGHT_SCALE: float = 1.5   # حجم النور وأنت ماشي
@export var JUMP_LIGHT_SCALE: float = 4.0   # الانفجار الضوئي لما تنط

var light_tween: Tween
var is_light_flashing: bool = false 

# --- إعدادات عداد الخوف / الوقت ---
@export_category("Fear & Darkness Settings")
@export var MAX_FEAR_TIME: float = 45.0  
var current_fear_time: float = 0.0
@export var fear_progress_bar: ProgressBar 

# عقوبة الخوف عند استخدام الداش
@export var DASH_FEAR_PENALTY: float = 3.0 

# --- إعدادات الكاميرا المستقلة واهتزازها ---
@export_category("Camera FX")
@export var camera: Camera2D 
@export var LOW_TIME_THRESHOLD: float = 0.25 
@export var SHAKE_INTENSITY: float = 2.5 
@export var CAMERA_FOLLOW_SPEED: float = 5.0 

var low_time_shake: float = 0.0
var dash_impact_shake: float = 0.0
var base_camera_position: Vector2

# --- إعدادات الميلان على السطوح المائلة ---
@export_category("Slope Alignment")
@export var SLOPE_ALIGN_SPEED: float = 12.0 

# --- إعدادات صدى المشي ---
@export_category("Footstep Echo")
@export var STEP_ECHO_INTERVAL: float = 0.22  
@export var STEP_ECHO_RADIUS: float = 70.0
var step_echo_timer: float = 0.0

# --- خصائص الاندفاع (Dash) ---
const DASH_SPEED = 650.0
const DASH_DURATION = 0.12  
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_dash: bool = true

# --- إعدادات تأثير الشبحية/التردد ---
@export_category("Dash Ghost Effect")
@export var GHOST_INTERVAL: float = 0.03 
@export var GHOST_COLOR: Color = Color(2.5, 0.5, 0.5, 0.7) 
var ghost_timer: float = 0.0

# --- مظاهر الـ Dash ---
@export_category("Dash Visuals")
@export var DASH_COLOR: Color = Color(3.0, 0.4, 0.4, 1.0)
var original_color: Color = Color.WHITE
var color_tween: Tween

# --- إعدادات تأثير الظلمة ---
@export_category("Vignette / Fear Shader")
@export var vignette_rect: ColorRect 

# --- القفز المزدوج ---
var jumps_left: int = 2

# --- مشاهد خارجية ---
@export_category("Effects")
@export var wave_scene: PackedScene

# --- الإشارة إلى العقد الداخلية ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var wk_audio: AudioStreamPlayer2D = $"wk audio"
@onready var jp_audio: AudioStreamPlayer2D = $"jp audio"
@onready var dh_audio: AudioStreamPlayer2D = $"dh audio"

var game_over = false

func _ready() -> void:
	original_color = animated_sprite.modulate
	
	current_fear_time = MAX_FEAR_TIME
	if fear_progress_bar:
		fear_progress_bar.max_value = MAX_FEAR_TIME
		fear_progress_bar.value = current_fear_time
		
	if camera:
		base_camera_position = camera.global_position

func _physics_process(delta: float) -> void:
	# ⚠️ إذا مات اللاعب، تجميد جميع المدخلات والحركات فوراً
	if game_over:
		return

	# 0. معالجة عداد الخوف وتأثيرات الكاميرا
	handle_fear_timer(delta)
	apply_camera_shake(delta)

	# 1. منطق الاندفاع (Dash)
	if is_dashing:
		dash_timer -= delta
		handle_ghost_trail(delta)
		
		if dash_timer <= 0:
			is_dashing = false
			fade_color_back()
			spawn_echo(240.0)
			
		move_and_slide()
		align_sprite_to_floor(delta)
		return

	# 2. الجاذبية وإعادة ضبط القفز والاندفاع
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jumps_left = 2
		can_dash = true

	# 3. القفز والقفز المزدوج
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			spawn_echo(180.0)
			jp_audio.pitch_scale = 1.1
			jp_audio.play()
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY * 0.92
			jumps_left -= 1
			spawn_echo(240.0)
			jp_audio.pitch_scale = 1.6
			jp_audio.play()

	# 4. الحركة الأفقية
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		
	update_animations(direction)

	# 6. صدى الخطوات
	handle_walk_echo(delta, direction)

	# 7. الاندفاع والصدى اليدوي
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash(direction)
		
	if Input.is_action_just_pressed("echo"):
		spawn_echo(150.0)

	move_and_slide()
	align_sprite_to_floor(delta)


func handle_fear_timer(delta: float) -> void:
	if current_fear_time > 0:
		current_fear_time -= delta
		
		if fear_progress_bar:
			fear_progress_bar.value = current_fear_time
			
		var time_ratio = current_fear_time / MAX_FEAR_TIME              

		if time_ratio <= LOW_TIME_THRESHOLD:
			var stress_factor = 1.0 - (time_ratio / LOW_TIME_THRESHOLD)
			low_time_shake = SHAKE_INTENSITY * stress_factor
		else:
			low_time_shake = 0.0

	# ⚠️ استدعاء دالة الموت مرة واحدة فقط
	if current_fear_time <= 0.0 and not game_over:
		current_fear_time = 0.0
		game_over_fear()


func apply_camera_shake(delta: float) -> void:
	if camera:
		dash_impact_shake = move_toward(dash_impact_shake, 0.0, delta * 15.0)
		var total_shake = low_time_shake + dash_impact_shake
		
		if CAMERA_FOLLOW_SPEED > 0:
			base_camera_position = base_camera_position.lerp(global_position, CAMERA_FOLLOW_SPEED * delta)
			
		var shake_offset = Vector2.ZERO
		if total_shake > 0:
			shake_offset = Vector2(
				randf_range(-total_shake, total_shake),
				randf_range(-total_shake, total_shake)
			)
			
		camera.global_position = base_camera_position + shake_offset

func start_dash(dir: float) -> void:
	dh_audio.play()
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	ghost_timer = 0.0
	
	current_fear_time = max(0.0, current_fear_time - DASH_FEAR_PENALTY)
	dash_impact_shake = 6.0 
	
	var dash_dir = dir if dir != 0 else (1.0 if velocity.x >= 0 else -1.0)
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0
	
	if color_tween and color_tween.is_running():
		color_tween.kill()
		
	color_tween = create_tween()
	color_tween.tween_property(animated_sprite, "modulate", DASH_COLOR, 0.03)

func add_fear_time(amount: float) -> void:
	if game_over: return
	
	current_fear_time = clamp(current_fear_time + amount, 0.0, MAX_FEAR_TIME)
	if fear_progress_bar:
		fear_progress_bar.value = current_fear_time
		
	if current_fear_time <= 0.0 and not game_over:
		current_fear_time = 0.0
		game_over_fear()

# --- 🎯 دالة الموت المحدثة والمحمية من التخريب ---
func game_over_fear() -> void:
	if game_over: return
	game_over = true
	
	# 1. إيقاف سرعة الجسم وتثبيته في مكانه
	velocity = Vector2.ZERO
	is_dashing = false
	
	# 2. تشغيل أنيميشن الموت فوراً بعد إلغاء أي تأثيرات لونية
	if color_tween and color_tween.is_running():
		color_tween.kill()
	animated_sprite.modulate = original_color
	animated_sprite.rotation = 0.0 # إعادة استقامة اللاعب
	
	animated_sprite.play("die")
	
	# 3. الانتظار حتى انتهاء الأنيميشن ثم إعادة المشهد
	await animated_sprite.animation_finished
	get_tree().reload_current_scene()

func align_sprite_to_floor(delta: float) -> void:
	if game_over: return
	
	var target_rotation: float = 0.0
	if is_on_floor():
		var floor_normal = get_floor_normal()
		target_rotation = floor_normal.angle() + (PI / 2.0)
	else:
		target_rotation = 0.0
	animated_sprite.rotation = lerp_angle(animated_sprite.rotation, target_rotation, SLOPE_ALIGN_SPEED * delta)

func handle_ghost_trail(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = GHOST_INTERVAL
		spawn_ghost()

func spawn_ghost() -> void:
	var ghost = Sprite2D.new()
	var current_texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.texture = current_texture
	ghost.global_position = global_position
	ghost.rotation = animated_sprite.rotation
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = GHOST_COLOR
	ghost.scale = animated_sprite.scale
	get_tree().current_scene.call_deferred("add_child", ghost)
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)

func fade_color_back() -> void:
	if color_tween and color_tween.is_running():
		color_tween.kill()
	color_tween = create_tween()
	color_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	color_tween.tween_property(animated_sprite, "modulate", original_color, 0.18)

func handle_walk_echo(delta: float, dir: float) -> void:
	if is_on_floor() and dir != 0:
		step_echo_timer -= delta
		if step_echo_timer <= 0.0:
			wk_audio.pitch_scale = randf_range(0.95, 1)
			wk_audio.volume_db = randf_range(-1, 1)
			wk_audio.play()
			spawn_echo(STEP_ECHO_RADIUS)
			step_echo_timer = STEP_ECHO_INTERVAL
	else:
		step_echo_timer = 0.0

func update_animations(dir: float) -> void:
	# حماية إضافية عدم تشغيل أي أنيميشن آخر أثناء الموت
	if game_over: return

	if not is_on_floor():
		animated_sprite.play("jamp")
	else:
		if dir != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")

func spawn_echo(radius: float) -> void:
	if wave_scene:
		var wave = wave_scene.instantiate()
		wave.global_position = global_position
		wave.max_radius = radius
		get_tree().current_scene.call_deferred("add_child", wave)
