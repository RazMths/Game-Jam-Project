extends Area2D

@export_category("Enemy Movement")
@export var SPEED: float = 60.0
@export var MOVE_DISTANCE: float = 120.0 

# --- جديد: إعدادات الطفو للأعلى والأسفل ---
@export_category("Hover Settings")
@export var HOVER_SPEED: float = 4.0      # سرعة حركة الطفو
@export var HOVER_AMPLITUDE: float = 12.0 # أقصى ارتفاع للطفو (بكسل)

@export_category("Willpower Rewards & Penalties")
@export var WILLPOWER_REWARD: float = 12.0 
@export var CONTACT_PENALTY: float = 10.0  

@export_category("Burst Effect Settings")
@export var BURST_PIECES_COUNT: int = 8  
@export var BURST_RADIUS: float = 80.0    
@export var BURST_DURATION: float = 0.35  

var start_x: float = 0.0
# --- جديد: متغيرات لحفظ نقطة البداية العمودية ووقت الطفو ---
var start_y: float = 0.0
var time_passed: float = 0.0 

var direction: int = 1
var fade_tween: Tween
var duration: float = 1.4

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sm_audio: AudioStreamPlayer2D = $"sm audio"
@onready var ph_audio: AudioStreamPlayer2D = $"ph audio"

func _ready() -> void:
	start_x = global_position.x
	# --- جديد: حفظ نقطة البداية العمودية (Y) ---
	start_y = global_position.y 
	
	body_entered.connect(_on_body_entered)
	
	if animated_sprite:
		animated_sprite.play()

func _physics_process(delta: float) -> void:
	# 1. الحركة الأفقية (يمين ويسار)
	global_position.x += SPEED * direction * delta
	
	# --- جديد: 2. حركة الطفو العمودية (أعلى وأسفل) ---
	time_passed += delta # زيادة الوقت تدريجياً
	# تطبيق معادلة الموجة الجيبية لتغيير الـ Y بسلاسة
	global_position.y = start_y + sin(time_passed * HOVER_SPEED) * HOVER_AMPLITUDE
	
	# 3. التحقق من المسافة وعكس الاتجاه
	if abs(global_position.x - start_x) >= MOVE_DISTANCE:
		direction *= -1
		if animated_sprite:
			animated_sprite.flip_h = (direction < 0)

func _on_body_entered(body: Node) -> void:
	# (باقي الكود هنا يبقى كما هو بدون أي تغيير)
	if body.name == "Player" or body.has_method("add_fear_time"):
		if "is_dashing" in body and body.is_dashing:
			body.add_fear_time(WILLPOWER_REWARD)
			
			if "dash_impact_shake" in body:
				body.dash_impact_shake = 9.0
				
			if body.has_method("spawn_echo"):
				body.spawn_echo(220.0)
				
			spawn_ghost_burst()
		else:
			if body.has_method("add_fear_time"):
				body.add_fear_time(-CONTACT_PENALTY)
				
			if "velocity" in body:
				ph_audio.pitch_scale = randf_range(0.9, 1.1)
				ph_audio.play()
				var push_dir = 1.0 if body.global_position.x > global_position.x else -1.0
				body.velocity.x = push_dir * 900.0
				body.velocity.y = -400.0

func spawn_ghost_burst() -> void:
	# (باقي دالة الانفجار تبقى كما هي بدون تغيير)
	var ad = sm_audio.duplicate() as AudioStreamPlayer2D
	get_tree().current_scene.add_child(ad)
	ad.play()
	monitoring = false
	
	if animated_sprite:
		animated_sprite.visible = false

	var current_texture: Texture2D = null
	if animated_sprite and animated_sprite.sprite_frames:
		var current_anim = animated_sprite.animation
		var current_frame = animated_sprite.frame
		current_texture = animated_sprite.sprite_frames.get_frame_texture(current_anim, current_frame)

	for i in range(BURST_PIECES_COUNT):
		var piece = Sprite2D.new()
		piece.texture = current_texture
		piece.global_position = global_position
		piece.scale = animated_sprite.scale if animated_sprite else Vector2.ONE
		piece.flip_h = animated_sprite.flip_h if animated_sprite else false
		piece.modulate = Color(2.0, 1.2, 1.2, 0.8) 
		get_tree().current_scene.add_child(piece)
		
		var angle = (TAU / BURST_PIECES_COUNT) * i + randf_range(-0.2, 0.2)
		var target_offset = Vector2.UP.rotated(angle) * randf_range(BURST_RADIUS * 0.7, BURST_RADIUS * 1.3)
		var target_pos = global_position + target_offset
		
		var tween = create_tween().set_parallel(true)
		tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(piece, "global_position", target_pos, BURST_DURATION)
		tween.tween_property(piece, "modulate:a", 0.0, BURST_DURATION)
		tween.tween_property(piece, "scale", piece.scale * 1.6, BURST_DURATION)
		tween.tween_property(piece, "rotation", randf_range(-PI, PI), BURST_DURATION)
		
		tween.finished.connect(piece.queue_free)

	get_tree().create_timer(BURST_DURATION).timeout.connect(queue_free)
