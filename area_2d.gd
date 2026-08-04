extends Area2D

@export_category("Room Transition Configuration")
@export var target_spawn: Marker2D         # 📍 نقطة الوصول في الغرفة الجديدة
@export var target_camera: Camera2D        # 🎥 الكاميرا الخاصة بالغرفة الجديدة
@export var echo_shader_rect: ColorRect    # ⬛ غطاء الشادر
@export var player: Node2D                 # 🏃‍♂️ اللاعب (اختياري، يكتشفه تلقائياً)

@export_category("Transition Settings")
@export var transition_duration: float = 0.4 # سرعة الإغلاق والفتح
@export var level_start_reveal: bool = true  # 🌟 هل ينفتح الشادر عند بداية اللعبة؟
@export var reveal_duration: float = 0.8     # مدة الانكشاف عند بداية اللعبة

var _is_transitioning: bool = false
var _shader_material: ShaderMaterial

func _ready() -> void:
	set_process(false)
	
	if echo_shader_rect and echo_shader_rect.material is ShaderMaterial:
		_shader_material = echo_shader_rect.material as ShaderMaterial

	body_entered.connect(_on_body_entered)
	
	# 🎯 كشف المرحلة عند البداية بدائرة تنفتح من موقع اللاعب
	if level_start_reveal and _shader_material:
		_setup_level_start_reveal()


# 🎯 يمكنك تعديل القيمة من الـ Inspector لزيادة البطء (مثلاً 2.0 أو 2.5)
func _setup_level_start_reveal() -> void:
	# 1. إغلاق الشاشه فوراً قبل أي انتظار لمنع أي ظهور خاطئ أو سريع
	if _shader_material:
		_shader_material.set_shader_parameter("transition_size", 0.0)
	
	# 2. انتظار إطارين لضمان استقرار أبعاد الشاشة وموقع الكاميرا تماماً
	await get_tree().process_frame
	await get_tree().process_frame

	# محاولة إيجاد اللاعب
	if not player:
		var players = get_tree().get_nodes_in_group("Player")
		if players.size() == 0:
			players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]

	if not player or not _shader_material:
		return

	# تأكيد إغلاق الشاشة وتحديث موقع اللاعب أولاً
	_shader_material.set_shader_parameter("transition_size", 0.0)
	set_process(true)
	_update_player_position_in_shader()

	# 3. فتح الدائرة ببطء وسلاسة عالية جداً
	var tween_reveal = create_tween()
	
	# استبدال منحنى الحركة بمنحنى Sine سينمائي وبطيء
	tween_reveal.set_ease(Tween.EASE_IN_OUT)
	tween_reveal.set_trans(Tween.TRANS_SINE)
	
	tween_reveal.tween_property(_shader_material, "shader_parameter/transition_size", 1.0, reveal_duration+1)

	await tween_reveal.finished
	if not _is_transitioning:
		set_process(false)

func _process(_delta: float) -> void:
	_update_player_position_in_shader()

# دالة موحدة لتحديث موضع اللاعب بالنسبة للشاشة
func _update_player_position_in_shader() -> void:
	if player and _shader_material:
		var viewport_size = get_viewport_rect().size
		var canvas_transform = get_viewport().get_canvas_transform()
		
		# موقع اللاعب الموحد (من 0.0 إلى 1.0) على مستوى الشاشة
		var player_screen_pos = (canvas_transform * player.global_position) / viewport_size
		_shader_material.set_shader_parameter("player_screen_pos", player_screen_pos)

func _on_body_entered(body: Node2D) -> void:
	if _is_transitioning:
		return

	if not _validate_player(body):
		return

	_start_room_transition()

func _validate_player(body: Node2D) -> bool:
	if player == null:
		if body.is_in_group("Player") or body.is_in_group("player") or "player" in body.name.to_lower():
			player = body
			return true
		return false
	return body == player

func _start_room_transition() -> void:
	_is_transitioning = true

	# إذا لم يكن هناك شادر، قم بالنقل وتغيير الكاميرا فوراً
	if not _shader_material:
		_teleport_and_switch_camera()
		_is_transitioning = false
		return

	set_process(true)

	# 1. إغلاق الشادر (تعتيم الشاشة كلياً متمركزاً على اللاعب)
	var tween_close = create_tween()
	tween_close.set_ease(Tween.EASE_IN)
	tween_close.set_trans(Tween.TRANS_QUAD)
	tween_close.tween_property(_shader_material, "shader_parameter/transition_size", 0.0, transition_duration+0.3)
	await tween_close.finished

	# 2. نقل اللاعب وتفعيل الكاميرا الجديدة والشاشة مغلقة
	_teleport_and_switch_camera()
	_update_player_position_in_shader() # تحديث موضع اللاعب فوراً بعد الانتقال للموقع الجديد

	# 3. فتح الشادر مرة أخرى كاشفاً الغرفة الجديدة من موقع الوصول
	var tween_open = create_tween()
	tween_open.set_ease(Tween.EASE_OUT)
	tween_open.set_trans(Tween.TRANS_CUBIC)
	tween_open.tween_property(_shader_material, "shader_parameter/transition_size", 1.0, transition_duration)
	await tween_open.finished

	set_process(false)
	_is_transitioning = false

func _teleport_and_switch_camera() -> void:
	# نقل موقع اللاعب
	if player and target_spawn:
		player.global_position = target_spawn.global_position

	# تحويل الرؤية للكاميرا الجديدة
	if target_camera:
		target_camera.make_current()
