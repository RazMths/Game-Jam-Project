extends StaticBody2D

@export var duration: float = 1.4

@onready var sprite = $MeshInstance2D 
var fade_tween: Tween

func _ready() -> void:
	# استخدام self_modulate يضمن التأثير على هذه العقدة فقط وليس العقد المرتبطة بها
	sprite.self_modulate.a = 0.0

func reveal_platform() -> void:
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
		
	# إظهار المنصة فوراً
	sprite.self_modulate.a = 1.0
	
	# بدء التلاشي الناعم
	fade_tween = create_tween()
	fade_tween.tween_property(sprite, "self_modulate:a", 0.0, duration)
