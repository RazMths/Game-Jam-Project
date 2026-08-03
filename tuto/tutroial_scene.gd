extends Node2D

@export var transition_rect: ColorRect 
@export var trigger_area: Area2D 

var shader_mat: ShaderMaterial
var is_triggered: bool = false

func _ready() -> void:
	if transition_rect and transition_rect.material:
		shader_mat = transition_rect.material as ShaderMaterial
		
		# ضبط أبعاد الشاشة للـ Shader
		var viewport_size = get_viewport_rect().size
		shader_mat.set_shader_parameter("screen_aspect", viewport_size.x / viewport_size.y)
		
		# 1. بداية الـ Level: الدائرة البيضاء تصغر وتنكمش (من 1.5 إلى 0.0)
		_animate_circle(1.5, 0.0, 1.0)

	if trigger_area:
		trigger_area.body_entered.connect(_on_area_body_entered)

func _on_area_body_entered(body: Node2D) -> void:
	if not is_triggered:
		is_triggered = true
		
		# انتظار 26 ثانية
		await get_tree().create_timer(23.0).timeout
		
		# 2. بعد 26 ثانية: الدائرة البيضاء ترجع تكبر وتتزايد (من 0.0 إلى 1.5)
		_animate_circle(0.0, 1.5, 1.2)

func _animate_circle(from_size: float, to_size: float, duration: float) -> void:
	if not shader_mat:
		return
		
	shader_mat.set_shader_parameter("circle_size", from_size)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(shader_mat, "shader_parameter/circle_size", to_size, duration)
