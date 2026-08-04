extends Node2D

@export var transition_rect: ColorRect 
@export var trigger_area: Area2D 
@export var player: Node2D # 🏃‍♂️ إضافة عقدة اللاعب هنا

var shader_mat: ShaderMaterial
var is_triggered: bool = false

func _ready() -> void:
	if transition_rect and transition_rect.material:
		shader_mat = transition_rect.material as ShaderMaterial
		
		# ضبط أبعاد الشاشة للـ Shader
		var viewport_size = get_viewport_rect().size
		shader_mat.set_shader_parameter("screen_aspect", viewport_size.x / viewport_size.y)
		
		# 🎯 تحديث موضع اللاعب أولاً، ثم بدء انكماش الدائرة في بداية المرحلة
		_update_player_position_in_shader()
		_animate_circle(1.5, 0.0, 1.0)

	if trigger_area:
		trigger_area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node2D) -> void:
	# إذا لم نحدد اللاعب في الـ Inspector، نأخذه تلقائياً من الـ body الذي دخل الـ Area
	if not player and body:
		player = body

	if not is_triggered:
		is_triggered = true
		
		# انتظار الوقت المحدد (23 ثانية حسب الكود)
		await get_tree().create_timer(23.0).timeout
		
		# 🎯 تحديث موقع اللاعب لحظة بدء التوسع لضمان تتبع موقعه الجديد
		_update_player_position_in_shader()
		_animate_circle(0.0, 1.5, 1.2)

# 🎯 دالة تحويل موقع اللاعب إلى نسبة مئوية إحداثية (0.0 إلى 1.0) وإرسالها للشادر
func _update_player_position_in_shader() -> void:
	if not player or not shader_mat:
		return
		
	var viewport_size = get_viewport_rect().size
	var canvas_transform = get_viewport().get_canvas_transform()
	
	# تحويل موقع اللاعب في العالم إلى موقع على الشاشة بنسبة مئوية
	var player_screen_pos = (canvas_transform * player.global_position) / viewport_size
	
	# إرسال المتغير للشادر (تأكد أن الشادر يحتوي على uniform vec2 player_screen_pos;)
	shader_mat.set_shader_parameter("player_screen_pos", player_screen_pos)

func _animate_circle(from_size: float, to_size: float, duration: float) -> void:
	if not shader_mat:
		return
		
	# تحديث موقع اللاعب قبل بدء الأنيماشن مباشرة
	_update_player_position_in_shader()
		
	shader_mat.set_shader_parameter("circle_size", from_size)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# 🎯 ربط تحديث موقع اللاعب مع كل إطار أثناء الأنيماشن لضمان تتبعه إذا كان يتحرك
	tween.tween_callback(_update_player_position_in_shader)
	tween.tween_property(shader_mat, "shader_parameter/circle_size", to_size, duration)
