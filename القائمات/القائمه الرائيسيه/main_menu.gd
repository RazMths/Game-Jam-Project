extends Control

# ربط العقد حسب شجرة المشهد عندك
@onready var dark_overlay: ColorRect = $CanvasLayer/background
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton
@onready var option_button: Button = $CanvasLayer/VBoxContainer/OptionButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/QuitButton
@onready var sl_audio: AudioStreamPlayer2D = $"CanvasLayer/sl audio"

# عقد التحكم بالصوت والشاشة الكاملة
@onready var audio_level = $"CanvasLayer/Audio Level"
@onready var fullscreen_check = $CanvasLayer/FullScreenCheck

# متغير الـ Shader
var shader_mat: ShaderMaterial

# متغيرات إضاءة العنوان والأعدادات العشوائية
@export var title_lights_enabled: bool = true
var title_light_timer: float = 0.0
var next_title_light_interval: float = 0.5 

@export var settings_lights_enabled: bool = true
var settings_light_timer: float = 0.0
var next_settings_light_interval: float = 1.2 # نبضات هادئة كل فترة

# هيكل إدارة موجات الصدى
class MenuEchoWave:
	var position: Vector2
	var radius: float = 0.0
	var opacity: float = 1.0
	var max_radius: float = 450.0
	var speed: float = 750.0

var active_waves: Array[MenuEchoWave] = []

@export var options_menu: Control

func _ready() -> void:
	if dark_overlay and dark_overlay.material:
		shader_mat = dark_overlay.material as ShaderMaterial

	# 1. ربط أزرار القائمة الرئيسية
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	option_button.pressed.connect(_on_option_pressed)

	# 2. ربط زر الشاشة الكاملة
	if fullscreen_check:
		if fullscreen_check is CheckBox or fullscreen_check is CheckButton:
			fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
			fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		elif fullscreen_check is Button:
			fullscreen_check.pressed.connect(_on_fullscreen_pressed)

	# 3. إعداد سلايدر التحكم بالصوت
	if audio_level and audio_level is Range:
		audio_level.min_value = 0.0
		audio_level.max_value = 1.0
		audio_level.step = 0.01
		audio_level.value = 1.0
		
		_on_audio_level_changed(1.0)
		audio_level.value_changed.connect(_on_audio_level_changed)

	# 4. ربط التمرير (Hover) لجميع العناصر
	var interactive_controls = [start_button, option_button, quit_button, fullscreen_check, audio_level]
	for control in interactive_controls:
		if control and control is Control:
			control.mouse_entered.connect(_on_control_hover.bind(control))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		spawn_menu_wave(get_global_mouse_position(), 500.0)

func _process(delta: float) -> void:
	# 1. تحديث موقع ضوء الفأرة للـ Shader
	var mouse_pos = get_global_mouse_position()
	if shader_mat:
		shader_mat.set_shader_parameter("mouse_position", mouse_pos)

	# 2. توليد إضاءة عشوائية حول العنوان
	if title_lights_enabled:
		_process_random_title_lights(delta)

	# 3. توليد إضاءة هادئة على خيارات الإعدادات (Full Screen و Audio Level)
	if settings_lights_enabled:
		_process_random_settings_lights(delta)

	# 4. تحديث حركة جميع الموجات
	_update_waves(delta)

# دالة إطلاق إضاءة عشوائية بطيئة حول العنوان
func _process_random_title_lights(delta: float) -> void:
	title_light_timer += delta
	if title_light_timer >= next_title_light_interval:
		title_light_timer = 0.0
		next_title_light_interval = randf_range(0.4, 0.8) 
		
		var title_node = $CanvasLayer/Title
		if title_node:
			var rect = title_node.get_global_rect()
			var margin = 40.0
			
			var random_x = randf_range(rect.position.x - margin, rect.position.x + rect.size.x + margin)
			var random_y = randf_range(rect.position.y - margin, rect.position.y + rect.size.y + margin)
			
			spawn_menu_wave(Vector2(random_x, random_y), randf_range(90.0, 170.0), 100.0)

# دالة إطلاق نبضات ضوئية على خيارات الإعدادات لجذب انتباه اللاعب
func _process_random_settings_lights(delta: float) -> void:
	settings_light_timer += delta
	if settings_light_timer >= next_settings_light_interval:
		settings_light_timer = 0.0
		next_settings_light_interval = randf_range(1.2, 2.2) # وقت هادئ ومتباعد
		
		# اختيار عشوائي بين Audio Level و FullScreenCheck
		var targets = []
		if audio_level: targets.append(audio_level)
		if fullscreen_check: targets.append(fullscreen_check)
		
		if targets.size() > 0:
			var target_node: Control = targets.pick_random()
			var rect = target_node.get_global_rect()
			var center = rect.position + (rect.size / 2.0)
			
			# موجة بطيئة وناعمة تركز على نود الخيار
			spawn_menu_wave(center, 130.0, 120.0)

# دالة إنشاء موجة صدى
func spawn_menu_wave(pos: Vector2, target_radius: float = 400.0, custom_speed: float = 750.0) -> void:
	if active_waves.size() >= 20:
		active_waves.pop_front()

	var wave = MenuEchoWave.new()
	wave.position = pos
	wave.max_radius = target_radius
	wave.speed = custom_speed
	active_waves.append(wave)

func _update_waves(delta: float) -> void:
	var positions: Array[Vector2] = []
	var radii: Array[float] = []
	var opacities: Array[float] = []
	var to_remove: Array[MenuEchoWave] = []

	for wave in active_waves:
		wave.radius += wave.speed * delta
		wave.opacity = lerp(1.0, 0.0, wave.radius / wave.max_radius)

		if wave.radius >= wave.max_radius:
			to_remove.append(wave)
		else:
			positions.append(wave.position)
			radii.append(wave.radius)
			opacities.append(wave.opacity)

	for wave in to_remove:
		active_waves.erase(wave)

	if shader_mat:
		shader_mat.set_shader_parameter("active_waves_count", positions.size())
		shader_mat.set_shader_parameter("wave_positions", positions)
		shader_mat.set_shader_parameter("wave_radii", radii)
		shader_mat.set_shader_parameter("wave_opacities", opacities)

# دالة التمرير فوق العناصر
func _on_control_hover(control: Control) -> void:
	if control:
		var btn_center = control.global_position + (control.size / 2.0)
		if sl_audio:
			sl_audio.pitch_scale = randf_range(0.9, 1.3)
			sl_audio.play()
		spawn_menu_wave(btn_center, 220.0, 750.0)

# --- الدوال الخاصة بالتحكم بالصوت والشاشة ---

func _on_fullscreen_toggled(button_pressed: bool) -> void:
	if button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_fullscreen_pressed() -> void:
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_audio_level_changed(value: float) -> void:
	var master_bus_index = AudioServer.get_bus_index("Master")
	if value <= 0.001:
		AudioServer.set_bus_mute(master_bus_index, true)
	else:
		AudioServer.set_bus_mute(master_bus_index, false)
		var db_val = linear_to_db(value)
		AudioServer.set_bus_volume_db(master_bus_index, db_val)

# --- أزرار القائمة والتأثيرات ---

func _on_option_pressed() -> void:
	if options_menu:
		options_menu.show()
		hide()
	else:
		get_tree().change_scene_to_file("res://القائمات/القائمه الاعدادات/options_menu.tscn")

func _on_start_pressed() -> void:
	_play_circle_transition(start_button, func():
		get_tree().change_scene_to_file("res://القائمات/loading_screen.tscn")
	)

func _on_quit_pressed() -> void:
	_play_circle_transition(quit_button, func():
		get_tree().quit()
	)

func _play_circle_transition(target_button: Button, on_complete: Callable) -> void:
	var transition_rect = $CanvasLayer.get_node_or_null("TransitionRect")
	if not transition_rect or not transition_rect.material:
		on_complete.call()
		return

	var mat = transition_rect.material as ShaderMaterial
	var btn_center = target_button.global_position + (target_button.size / 2.0)
	var viewport_size = get_viewport_rect().size
	var normalized_center = btn_center / viewport_size
	
	mat.set_shader_parameter("circle_center", normalized_center)
	mat.set_shader_parameter("screen_aspect", viewport_size.x / viewport_size.y)
	
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(mat, "shader_parameter/circle_size", 1.5, 0.6)
	tween.finished.connect(on_complete)
