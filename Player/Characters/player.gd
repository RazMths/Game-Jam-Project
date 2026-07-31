extends CharacterBody2D

# --- الثوابت والإعدادات الأساسية ---
@export_category("Movement Settings")
@export var SPEED = 280.0           
@export var JUMP_VELOCITY = -380.0  
@export var GRAVITY = 850.0         
@export var ACCELERATION = 2400.0   
@export var DECELERATION = 2800.0   

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

# --- إعدادات تأثير الشبحية/التردد (Dash Trail / Echo Effect) ---
@export_category("Dash Ghost Effect")
@export var GHOST_INTERVAL: float = 0.03 # معدل إصدار أطياف التردد (كل 0.03 ثانية)
@export var GHOST_COLOR: Color = Color(2.5, 0.5, 0.5, 0.7) # لون طيف التردد المتوهج
var ghost_timer: float = 0.0

# --- مظاهر الـ Dash المتشبعة ---
@export_category("Dash Visuals")
@export var DASH_COLOR: Color = Color(3.0, 0.4, 0.4, 1.0)
var original_color: Color = Color.WHITE
var color_tween: Tween

# --- القفز المزدوج ---
var jumps_left: int = 2

# --- مشاهد خارجية ---
@export_category("Effects")
@export var wave_scene: PackedScene

# --- الإشارة إلى عقدة التحريكات ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	original_color = animated_sprite.modulate

func _physics_process(delta: float) -> void:
	# 1. منطق الاندفاع (Dash)
	if is_dashing:
		dash_timer -= delta
		
		# توليد أطياف تردد خلف اللاعب أثناء الحركة
		handle_ghost_trail(delta)
		
		if dash_timer <= 0:
			is_dashing = false
			fade_color_back()
			spawn_echo(240.0)
			
		move_and_slide()
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
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY * 0.92
			jumps_left -= 1
			spawn_echo(240.0)

	# 4. الحركة الأفقية
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		animated_sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELERATION * delta)
		
	update_animations(direction)

	# 5. صدى الخطوات
	handle_walk_echo(delta, direction)

	# 6. الاندفاع والصدى اليدوي
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash(direction)
		
	if Input.is_action_just_pressed("echo"):
		spawn_echo(150.0)

	move_and_slide()

# --- دالة توليد أطياف التردد (Ghosts) ---
func handle_ghost_trail(delta: float) -> void:
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = GHOST_INTERVAL
		spawn_ghost()

func spawn_ghost() -> void:
	# إنشاء عقدة Sprite جديدة برمجياً لتأخذ شكل فريم اللاعب الحالي
	var ghost = Sprite2D.new()
	
	# أخذ النسيج الحالي (Texture) والإطار الحالي من AnimatedSprite2D
	var current_texture = animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	ghost.texture = current_texture
	ghost.global_position = global_position
	ghost.flip_h = animated_sprite.flip_h
	ghost.modulate = GHOST_COLOR
	ghost.scale = animated_sprite.scale
	
	# إضافته للمشهد الرئيسي حتى يظل ثابتاً في مكانه بينما يتحرك اللاعب
	get_tree().current_scene.add_child(ghost)
	
	# عمل تلاشي سريع للطيف وتدميره فور اختفائه
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.tween_callback(ghost.queue_free)

# --- دالة بدء الداش ---
func start_dash(dir: float) -> void:
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	ghost_timer = 0.0 # إطلاق أول طيف فوراً
	
	var dash_dir = dir if dir != 0 else (1.0 if velocity.x >= 0 else -1.0)
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0
	
	if color_tween and color_tween.is_running():
		color_tween.kill()
		
	color_tween = create_tween()
	color_tween.tween_property(animated_sprite, "modulate", DASH_COLOR, 0.03)

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
			spawn_echo(STEP_ECHO_RADIUS)
			step_echo_timer = STEP_ECHO_INTERVAL
	else:
		step_echo_timer = 0.0

func update_animations(dir: float) -> void:
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
		get_tree().current_scene.add_child(wave)
