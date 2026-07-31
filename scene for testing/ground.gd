extends StaticBody2D

@onready var sprite = $MeshInstance2D # أو ColorRect حسب ما استخدمت
var fade_tween: Tween

func _ready() -> void:
	# جعل المنصة مخفية في بداية اللعبة
	sprite.modulate.a = 0.0

# هذه الدالة تناديها موجة الصدى عندما تلمس المنصة
func reveal_platform() -> void:
	# إذا كان هناك تأثير تلاشي شغال حالياً، نلغيه ونبدأ من جديد
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	# 1. إظهار المنصة فوراً
	sprite.modulate.a = 1.0
	
	# 2. عمل تلاشي تدريجي (Fade out) خلال ثانيتين مثلاً
	fade_tween = create_tween()
	fade_tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
