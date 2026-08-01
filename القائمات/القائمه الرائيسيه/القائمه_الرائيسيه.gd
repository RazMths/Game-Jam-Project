extends Control

@export var options_menu: Control




func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_opsions_pressed() -> void:
	hide() # إخفاء قائمة التوقف
	if options_menu:
		options_menu.show() # إظهار قائمة الإعدادات
