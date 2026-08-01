extends Control

# قم بسحب نود قائمة الإعدادات هنا من شجرة النودات (Node Tree) في المحرر
@export var options_menu: Control

func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_opsions_pressed() -> void:
	# 1. إذا كنت رابط نود الإعدادات داخل نفس المشهد عن طريق Inspector
	if options_menu:
		options_menu.show() # إظهار قائمة الإعدادات فوق القائمة الحالية
		hide() # إخفاء القائمة الرئيسية
	else:
		# 2. الانتقال لمشهد آخر في حالة عدم الربط
		get_tree().change_scene_to_file("res://القائمات/القائمه الاعدادات/options_menu.tscn")

func _on_resume_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
