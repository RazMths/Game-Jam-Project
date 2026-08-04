extends Control

@onready var dark_overlay: ColorRect = $CanvasLayer/ColorRect
@onready var start_button: Button = $CanvasLayer/VBoxContainer/StartButton
@onready var quit_button: Button = $CanvasLayer/VBoxContainer/QuitButton
@onready var sl_audio: AudioStreamPlayer2D = $"CanvasLayer/sl audio"

@onready var audio_level = $"CanvasLayer/Audio Level"
@onready var fullscreen_check = $CanvasLayer/FullScreenCheck

var shader_mat: ShaderMaterial

@export var title_lights_enabled: bool = true
var title_light_timer: float = 0.0
var next_title_light_interval: float = 0.5 

@export var settings_lights_enabled: bool = true
var settings_light_timer: float = 0.0
var next_settings_light_interval: float = 1.2 

class MenuEchoWave:
	var position: Vector2
	var radius: float = 0.0
	var opacity: float = 1.0
	var max_radius: float = 0.35
	var speed: float = 0.4

var active_waves: Array[MenuEchoWave] = []

@export var options_menu: Control

func _ready() -> void:
	if dark_overlay and dark_overlay.material:
		shader_mat = dark_overlay.material as ShaderMaterial

	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	if fullscreen_check:
		if fullscreen_check is CheckBox or fullscreen_check is CheckButton:
			fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
			fullscreen_check.toggled.connect(_on_fullscreen_toggled)
		elif fullscreen_check is Button:
			fullscreen_check.pressed.connect(_on_fullscreen_pressed)

	if audio_level and audio_level is Range:
		audio_level.min_value = 0.0
		audio_level.max_value = 1.0
		audio_level.step = 0.01
		audio_level.value = 1.0
		_on_audio_level_changed(1.0)
		audio_level.value_changed.connect(_on_audio_level_changed)

	var interactive_controls = [start_button, quit_button, fullscreen_check, audio_level]
	for control in interactive_controls:
		if control and control is Control:
			control.mouse_entered.connect(_on_control_hover.bind(control))

# 🎯 تحويل موضع العقدة أو الماوس مباشرة إلى نسبة UV دقيقة (0.0 إلى 1.0) اعتماداً على Viewport الشاشة
func _node_to_uv(node: Control) -> Vector2:
	var vp_size = get_viewport_rect().size
	if vp_size.x == 0.0 or vp_size.y == 0.0:
		return Vector2.ZERO
	var screen_pos = node.get_global_transform_with_canvas().origin + (node.size * node.get_global_transform_with_canvas().get_scale() / 2.0)
	return screen_pos / vp_size

func _mouse_to_uv() -> Vector2:
	var vp_size = get_viewport_rect().size
	if vp_size.x == 0.0 or vp_size.y == 0.0:
		return Vector2.ZERO
	return get_viewport().get_mouse_position() / vp_size

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 🎯 تم توسيع نصف قطر موجة الضغطة إلى 0.38 مع تسريع طفيف للانتقال
		spawn_menu_wave(_mouse_to_uv(), 0.38, 0.45)

func _process(delta: float) -> void:
	var vp_size = get_viewport_rect().size
	if shader_mat and vp_size.y > 0.0:
		shader_mat.set_shader_parameter("mouse_position", _mouse_to_uv())
		shader_mat.set_shader_parameter("screen_aspect", vp_size.x / vp_size.y)

	if title_lights_enabled:
		_process_random_title_lights(delta)

	if settings_lights_enabled:
		_process_random_settings_lights(delta)

	_update_waves(delta)

func _process_random_title_lights(delta: float) -> void:
	title_light_timer += delta
	if title_light_timer >= next_title_light_interval:
		title_light_timer = 0.0
		next_title_light_interval = randf_range(0.8, 1.4) 
		
		var title_node = $CanvasLayer/Title
		if title_node:
			var base_uv = _node_to_uv(title_node)
			# نطاق أوسع قليلاً لإحداثيات التوهج حول العنوان
			var offset_uv = Vector2(randf_range(-0.14, 0.14), randf_range(-0.07, 0.07))
			# 🎯 تم تكبير حجم موجات العنوان إلى مدى بين 0.18 و 0.26
			spawn_menu_wave(base_uv + offset_uv, randf_range(0.25, 0.3), 0.20)

func _process_random_settings_lights(delta: float) -> void:
	settings_light_timer += delta
	if settings_light_timer >= next_settings_light_interval:
		settings_light_timer = 0.0
		next_settings_light_interval = randf_range(1.2, 2.2)
		
		var targets = []
		if audio_level: targets.append(audio_level)
		if fullscreen_check: targets.append(fullscreen_check)
		
		if targets.size() > 0:
			var target_node: Control = targets.pick_random()
			# 🎯 تم تكبير حجم موجة خيارات الإعدادات إلى 0.22
			spawn_menu_wave(_node_to_uv(target_node), 0.32, 0.25)

func spawn_menu_wave(uv_pos: Vector2, target_radius: float = 0.35, custom_speed: float = 0.4) -> void:
	if active_waves.size() >= 15:
		active_waves.pop_front()

	var wave = MenuEchoWave.new()
	wave.position = uv_pos
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

func _on_control_hover(control: Control) -> void:
	if control:
		if sl_audio:
			sl_audio.pitch_scale = randf_range(0.8, 1.1)
			sl_audio.play()
		# 🎯 تم توسيع موجة حومة الماوس على الأزرار إلى 0.25
		spawn_menu_wave(_node_to_uv(control), 0.32, 0.35)

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
	var normalized_center = _node_to_uv(target_button)
	var vp_size = get_viewport_rect().size
	
	mat.set_shader_parameter("circle_center", normalized_center)
	mat.set_shader_parameter("screen_aspect", vp_size.x / vp_size.y)
	
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(mat, "shader_parameter/circle_size", 1.5, 0.6)
	tween.finished.connect(on_complete)
