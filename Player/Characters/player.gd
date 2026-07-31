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

# --- القفز المزدوج ---
var jumps_left: int = 2

# --- مشاهد خارجية ---
@export_category("Effects")
@export var wave_scene: PackedScene

# --- الإشارة إلى عقدة التحريكات ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. منطق الاندفاع (Dash)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
			# --- التغيير هنا: إطلاق صدى قوي فور وصول اللاعب لنقطة نهاية الداش (الموقع ب) ---
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

# --- دالة بدء الداش ---
func start_dash(dir: float) -> void:
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	var dash_dir = dir if dir != 0 else (1.0 if velocity.x >= 0 else -1.0)
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0
	# تم إزالة spawn_echo من هنا ليتم إطلاقها عند الوصول فقط

# --- باقي الدوارل كما هي ---
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
