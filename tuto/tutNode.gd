extends Node2D

@export_category("Lighting Setup")
@export var echo_shader_rect: ColorRect  # ⬛ غطاء الشادر
@export var player: Node2D               # 🏃‍♂️ عقدة اللاعب

# مصفوفة لمتابعة موجات الصدى النشطة
var active_waves: Array = []

func _process(_delta: float) -> void:
	if not echo_shader_rect or not echo_shader_rect.material:
		return
		
	var mat = echo_shader_rect.material as ShaderMaterial
	var viewport_size = get_viewport_rect().size
	var canvas_transform = get_viewport().get_canvas_transform()
	
	# 🎯 1. تحديث موقع اللاعب بنسبة مئوية (0.0 إلى 1.0) لضمان الاستقلالية عن Full Screen
	if player:
		var player_screen_pos = (canvas_transform * player.global_position) / viewport_size
		mat.set_shader_parameter("player_screen_pos", player_screen_pos)
		
	# 🎯 2. معالجة وتحديث موجات الصدى (Echoes) بنطاق موحد متوافق مع الشاشة
	_update_echoes_in_shader(mat, viewport_size, canvas_transform)

func _update_echoes_in_shader(mat: ShaderMaterial, viewport_size: Vector2, canvas_transform: Transform2D) -> void:
	# تنظيف الموجات غير الصالحة
	active_waves = active_waves.filter(func(wave): return is_instance_valid(wave))
	
	var positions: Array = []
	var radii: Array = []
	var opacities: Array = []
	
	# 🎯 أخذ معامل زوم الكاميرا الحالي من التحويل مباشرة
	var zoom_scale: float = canvas_transform.get_scale().y
	
	for wave in active_waves:
		# 1. تحويل موضع الموجة إلى إحداثيات شاشة موحدة (0.0 إلى 1.0)
		var screen_pos = (canvas_transform * wave.global_position) / viewport_size
		positions.append(screen_pos)
		
		# 2. تحويل نصف القطر لنسبة مئوية + مراعاة زوم الكاميرا
		if "current_radius" in wave:
			var normalized_radius = (wave.current_radius * zoom_scale) / viewport_size.y
			radii.append(normalized_radius)
		else:
			radii.append(0.0)
			
		if "opacity" in wave:
			opacities.append(wave.opacity)
		else:
			opacities.append(1.0)
			
	# إرسال البيانات الموحدة للـ Shader
	mat.set_shader_parameter("echo_positions", positions)
	mat.set_shader_parameter("echo_radii", radii)
	mat.set_shader_parameter("echo_opacities", opacities)
	mat.set_shader_parameter("active_echoes_count", active_waves.size())
# دالة يمكن استدعاؤها من أي مكان لإضافة موجة صدى جديدة
func register_wave(wave_node: Node2D) -> void:
	if is_instance_valid(wave_node) and not active_waves.has(wave_node):
		active_waves.append(wave_node)
