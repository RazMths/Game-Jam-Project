extends Control

@onready var dark_overlay: ColorRect = $CanvasLayer/ColorRect
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/QuitButton
@onready var sl_audio: AudioStreamPlayer2D = $"CanvasLayer/sl audio"
@onready var option_button: Button = $CanvasLayer/VBoxContainer/OptionButton
@onready var transition_rect: ColorRect = $CanvasLayer/TransitionRect

var shader_mat: ShaderMaterial

# متغيرات للتحكم بنبضات إضاءة العنوان العشوائية
@export var title_lights_enabled: bool = true
var title_light_timer: float = 0.0
var next_title_light_interval: float = 0.5 # زيادة الوقت بين النبضات قليلاً لتكون أهدأ

# هيكل إدارة موجات الصدى في القائمة
class MenuEchoWave:
	var position: Vector2
	var radius: float = 0.0
	var opacity: float = 1.0
	var max_radius: float = 450.0
	var speed: float = 750.0 # السرعة الافتراضية للموجات السريعة

var active_waves: Array[MenuEchoWave] = []

@export var options_menu: Control

func _ready() -> void:
	if dark_overlay and dark_overlay.material:
		shader_mat = dark_overlay.material as ShaderMaterial

	# ربط أزرار القائمة
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	option_button.pressed.connect(_on_option_pressed)

	# ربط التمرير (Hover) لجميع الأزرار لإطلاق موجة
	for btn in [start_button, quit_button]:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))

func _input(event: InputEvent) -> void:
	# إطلاق موجة صدى عند الكبس بأي زر بالفأرة في أي مكان
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_menu_wave(get_global_mouse_position(), 500.0)

func _process(delta: float) -> void:
	# 1. تحديث موقع ضوء الفأرة بدقة
	var mouse_pos = get_global_mouse_position()
	if shader_mat:
		shader_mat.set_shader_parameter("mouse_position", mouse_pos)

	# 2. توليد إضاءة عشوائية حول العنوان
	if title_lights_enabled:
		_process_random_title_lights(delta)

	# 3. تحديث حركة جميع الموجات (بما فيها إضاءة العنوان)
	_update_waves(delta)

# دالة إطلاق إضاءة عشوائية بطيئة حول العنوان
func _process_random_title_lights(delta: float) -> void:
	title_light_timer += delta
	if title_light_timer >= next_title_light_interval:
		title_light_timer = 0.0
		# فترات ظهور متباعدة وهادئة
		next_title_light_interval = randf_range(0.4, 0.8) 
		
		var title_node = $CanvasLayer/Title
		if title_node:
			var rect = title_node.get_global_rect()
			var margin = 40.0
			
			var random_x = randf_range(rect.position.x - margin, rect.position.x + rect.size.x + margin)
			var random_y = randf_range(rect.position.y - margin, rect.position.y + rect.size.y + margin)
			var random_pos = Vector2(random_x, random_y)
			
			var random_radius = randf_range(90.0, 170.0)
			
			# استدعاء الموجة مع تحديد سرعة بطيئة خصيصاً للعنوان (مثلاً 100.0 بدلاً من 750.0)
			spawn_menu_wave(random_pos, random_radius, 100.0)

# دالة إنشاء موجة صدى (مع إضافة برامتر اختياري للسرعة custom_speed)
func spawn_menu_wave(pos: Vector2, target_radius: float = 400.0, custom_speed: float = 750.0) -> void:
	if active_waves.size() >= 10:
		active_waves.pop_front()

	var wave = MenuEchoWave.new()
	wave.position = pos
	wave.max_radius = target_radius
	wave.speed = custom_speed # تعيين السرعة الخاصة بالموجة
	active_waves.append(wave)

func _update_waves(delta: float) -> void:
	var positions: Array[Vector2] = []
	var radii: Array[float] = []
	var opacities: Array[float] = []

	var to_remove: Array[MenuEchoWave] = []

	for wave in active_waves:
		# تحريك الموجة حسب سرعتها المحددة (سريعة للماوس / بطيئة للعنوان)
		wave.radius += wave.speed * delta
		wave.opacity = lerp(1.0, 0.0, wave.radius / wave.max_radius)

		if wave.radius >= wave.max_radius:
			to_remove.append(wave)
		else:
			positions.append(wave.position)
			radii.append(wave.radius)
			opacities.append(wave.opacity)

	# تنظيف الموجات المنتهية
	for wave in to_remove:
		active_waves.erase(wave)

	# إرسال بيانات الموجات للـ Shader
	if shader_mat:
		shader_mat.set_shader_parameter("active_waves_count", positions.size())
		shader_mat.set_shader_parameter("wave_positions", positions)
		shader_mat.set_shader_parameter("wave_radii", radii)
		shader_mat.set_shader_parameter("wave_opacities", opacities)

func _on_button_hover(btn: Button) -> void:
	var btn_center = btn.global_position + (btn.size / 2.0)
	sl_audio.pitch_scale = randf_range(0.9, 1.3)
	sl_audio.play()
	spawn_menu_wave(btn_center, 200.0, 750.0) # موجة سريعة للتمرير

func _on_option_pressed() -> void:
	# 1. إذا كنت رابط نود الإعدادات داخل نفس المشهد عن طريق Inspector
	if options_menu:
		options_menu.show() # إظهار قائمة الإعدادات فوق القائمة الحالية
		hide() # إخفاء القائمة الرئيسية
	else:
		# 2. الانتقال لمشهد آخر في حالة عدم الربط
		get_tree().change_scene_to_file("res://القائمات/القائمه الاعدادات/options_menu.tscn")

func _on_start_pressed() -> void:
	# تشغيل تأثير القرص من موقع زر Start ثم الانتقال لشاشة التحميل
	_play_circle_transition(start_button, func():
		get_tree().change_scene_to_file("res://القائمات/loading_screen.tscn") # استبدل بمشهد التحميل عندك
	)

func _on_quit_pressed() -> void:
	# تشغيل تأثير القرص من موقع زر Quit ثم الخروج من اللعبة
	_play_circle_transition(quit_button, func():
		get_tree().quit()
	)

# دالة عامة لتشغيل أنيميشن القرص الأبيض من أي زر
func _play_circle_transition(target_button: Button, on_complete: Callable) -> void:
	var transition_rect = $CanvasLayer/TransitionRect # تأكد من اسم عقدة الـ ColorRect
	
	if not transition_rect or not transition_rect.material:
		# إذا لم تكن العقدة مجهزة، نفّذ الأمر مباشرة
		on_complete.call()
		return

	var mat = transition_rect.material as ShaderMaterial
	
	# 1. تحديد مركز الدائرة الأبيض من موقع الزر المكبوس
	var btn_center = target_button.global_position + (target_button.size / 2.0)
	var viewport_size = get_viewport_rect().size
	var normalized_center = btn_center / viewport_size
	
	mat.set_shader_parameter("circle_center", normalized_center)
	mat.set_shader_parameter("screen_aspect", viewport_size.x / viewport_size.y)
	
	# 2. حجب الفأرة لمنع أي ضغطات إضافية أثناء الأنيميشن
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 3. أنيميشن تكبير القرص الأبيض
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# تكبير الدائرة حتى تغطي الشاشة بالكامل خلال 0.6 ثانية
	tween.tween_property(mat, "shader_parameter/circle_size", 1.5, 0.6)
	
	# 4. تنفيذ الخروج أو الانتقال عند انتهاء التغطية
	tween.finished.connect(on_complete)
