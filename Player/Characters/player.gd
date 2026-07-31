extends CharacterBody2D

# --- الثوابت والإعدادات الأساسية ---
const SPEED = 220.0           # سرعة الحركة الأفقيّة
const JUMP_VELOCITY = -420.0  # قوة القفز
const GRAVITY = 980.0         # الجاذبية الأرضية
const FRICTION = 1200.0       # قوة التباطؤ عند التوقف (مرتبطة بـ delta)

# --- خصائص الاندفاع (Dash) ---
const DASH_SPEED = 650.0      # سرعة الاندفاع السريع
const DASH_DURATION = 0.15    # مدة الاندفاع بالثواني
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_dash: bool = true

# --- القفز المزدوج ---
var jumps_left: int = 2       # عدد القفزات المتاحة

# --- مشاهد خارجية ---
@export var wave_scene: PackedScene # مشهد موجة الـ Echo

# --- الإشارة إلى عقدة التحريكات ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# 1. منطق الاندفاع (Dash)
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	# 2. الجاذبية وإعادة ضبط القفز والاندفاع عند ملامسة الأرض
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
			velocity.y = JUMP_VELOCITY * 0.9
			jumps_left -= 1
			spawn_echo(240.0)

	# 4. الحركة الأفقية والتباطؤ
	var direction := Input.get_axis("left", "right")
	if direction != 0:
		velocity.x = direction * SPEED
		# تدوير وجه الشخصية أفقياً حسب اتجاه الحركة
		animated_sprite.flip_h = (direction < 0)
	else:
		# تباطؤ ناعم وثابت بغض النظر عن سرعة الجهاز
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	update_animations(direction)

	
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash(direction)
		
	if Input.is_action_just_pressed("echo"):
		spawn_echo(150.0)

	move_and_slide()

# --- دالة التحكم في التحريكات ---
func update_animations(dir: float) -> void:
	if not is_on_floor():
		animated_sprite.play("jamp")
	else:
		if dir != 0:
			animated_sprite.play("run")
		else:
			animated_sprite.play("idle")


func start_dash(dir: float) -> void:
	is_dashing = true
	can_dash = false
	dash_timer = DASH_DURATION
	var dash_dir = dir if dir != 0 else (1.0 if velocity.x >= 0 else -1.0)
	velocity.x = dash_dir * DASH_SPEED
	velocity.y = 0
	spawn_echo(220.0)


func spawn_echo(radius: float) -> void:
	if wave_scene:
		var wave = wave_scene.instantiate()
		wave.global_position = global_position
		wave.max_radius = radius
		get_tree().current_scene.add_child(wave)
