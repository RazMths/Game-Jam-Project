extends CharacterBody2D

# --- CONSTANTS & SETTINGS ---
const SPEED = 220.0
const JUMP_VELOCITY = -420.0
const GRAVITY = 980.0

# Dash properties
const DASH_SPEED = 650.0
const DASH_DURATION = 0.15
var is_dashing: bool = false
var dash_timer: float = 0.0
var can_dash: bool = true

# Double Jump
var jumps_left: int = 2

# Wave Pulse Scene
@export var wave_scene: PackedScene

func _physics_process(delta: float) -> void:
	# 1. Dash Logic
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
		move_and_slide()
		return

	# 2. Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		jumps_left = 2
		can_dash = true

	# 3. Jump & Double Jump
	if Input.is_action_just_pressed("jump"): # Space / W
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			jumps_left -= 1
			spawn_echo(180.0)
		elif jumps_left > 0:
			velocity.y = JUMP_VELOCITY * 0.9
			jumps_left -= 1
			spawn_echo(240.0) # قفزة مزدوجة بموجة أكبر

	# 4. Horizontal Movement
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 0.15)

	# 5. Dash Trigger (Press Shift)
	if Input.is_action_just_pressed("dash") and can_dash:
		start_dash(direction)

	# 6. Manual Echo Pulse (Press J)
	if Input.is_action_just_pressed("echo"):
		spawn_echo(150.0)

	move_and_slide()

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
		get_parent().add_child(wave)
