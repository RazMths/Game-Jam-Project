extends Sprite2D
# تم تغييرها إلى Area2D لتتعرف على تصادم الأجسام

# 1. تعريف المتغيرات المطلوبة لتفادي الأخطاء
@export var cutscene_path: String = "res://tuto/last_video.tscn"
@export var player: Node2D = null

var _is_transitioning: bool = false

# 2. دالة الدخول (مكتوبة مرة واحدة فقط)
func _on_body_entered(body: Node2D) -> void:
	print("دخل شيء إلى الباب: ", body.name)
	
	if _is_transitioning:
		return
		
	# التعرّف على اللاعب
	if player == null:
		if body.is_in_group("player") or body.name.to_lower().contains("player"):
			player = body
		else:
			print("تنبيه: الجسم ليس هو اللاعب المعرف!")
			return
	elif body != player:
		return

	# إذا كان الجسم هو اللاعب، نقوم بالانتقال
	_is_transitioning = true
	go_to_cutscene()

# 3. دالة الانتقال إلى المشهد السينمائي
func go_to_cutscene() -> void:
	var error = get_tree().change_scene_to_file(cutscene_path)
	if error != OK:
		print("خطأ في الانتقال إلى الكتسين")
		_is_transitioning = false # إعادة التفعيل في حال فشل الانتقال
