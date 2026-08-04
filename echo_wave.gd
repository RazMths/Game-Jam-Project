extends Area2D

@export var max_radius: float = 1500.0
@export var expand_speed: float = 350.0
@export var fade_duration: float = 1.5

# --- إعدادات رسم وتلاشي الحلقة الخارجية ---
@export var ring_color: Color = Color(0.0, 0.7, 1.0, 0.8)
@export var ring_width: float = 4.0
@export var ring_fade_ratio: float = 0.75

var current_radius: float = 0.0
var opacity: float = 1.0
var fade_timer: float = 0.0

@onready var collision_shape = $CollisionShape2D

static var active_waves_list: Array = []

func _ready() -> void:
	if not active_waves_list.has(self):
		active_waves_list.append(self)

func _process(delta: float) -> void:
	# 1. التوسع والتلاشي للـ Shader
	if current_radius < max_radius:
		current_radius += expand_speed * delta
		opacity = lerp(1.0, 0.4, current_radius / max_radius)
	else:
		fade_timer += delta
		opacity = lerp(0.4, 0.0, fade_timer / fade_duration)
		if fade_timer >= fade_duration:
			queue_free()

	# 2. تحديث التصادم
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = current_radius

	# 3. إعادة رسم الخط في عالم اللعبة
	queue_redraw()

	# 4. تحديث الـ Shader بالقيم النسبية الصحيحة
	_update_shader_arrays()

# دالة الرسم بالشفافية المطلوبة
func _draw() -> void:
	var ring_progress = current_radius / (max_radius * ring_fade_ratio)
	var ring_alpha = clamp(1.0 - ring_progress, 0.0, 1.0) * opacity
	
	if ring_alpha > 0.0 and current_radius > 0.0:
		var current_color = ring_color
		current_color.a *= ring_alpha
		draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 64, current_color, ring_width, true)

func _exit_tree() -> void:
	active_waves_list.erase(self)
	_update_shader_arrays()

func _update_shader_arrays() -> void:
	var shader_node = get_tree().current_scene.find_child("ColorRect", true, false)
	if not shader_node or not shader_node.material:
		return
		
	var mat = shader_node.material as ShaderMaterial
	var canvas_transform = get_viewport().get_canvas_transform()
	var viewport_size = get_viewport_rect().size
	
	var positions: Array[Vector2] = []
	var radii: Array[float] = []
	var opacities: Array[float] = []
	
	# 🎯 الحصول على مقياس الزوم من الكاميرا
	var zoom_scale: float = canvas_transform.get_scale().y
	
	for wave in active_waves_list:
		if is_instance_valid(wave):
			# 1. تحويل الموضع لنظام النسب المئوية (من 0.0 إلى 1.0) ليتطابق مع الشادر
			var normalized_pos = (canvas_transform * wave.global_position) / viewport_size
			positions.append(normalized_pos)
			
			# 2. تحويل نصف القطر لنسبة مئوية مع مراعاة زوم الكاميرا وارتفاع Viewport
			var normalized_radius = (wave.current_radius * zoom_scale) / viewport_size.y
			radii.append(normalized_radius)
			
			opacities.append(wave.opacity)
	
	mat.set_shader_parameter("active_echoes_count", positions.size())
	mat.set_shader_parameter("echo_positions", positions)
	mat.set_shader_parameter("echo_radii", radii)
	mat.set_shader_parameter("echo_opacities", opacities)
