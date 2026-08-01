extends Control
@export var options_menu: Control
func _ready() -> void:
	# 1. تفعيل عمل هذا السكربت دائماً حتى لو كانت اللعبة متوقفة
	process_mode = Node.PROCESS_MODE_ALWAYS
	# 2. إخفاء قائمة التوقف عند بداية التشغيل
	if has_node("CanvasLayer"):
		$CanvasLayer.hide()

func _input(event: InputEvent) -> void:
	# 3. الاستجابة لضغط زر ESC أو زر pause
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("Pause"):
		toggle_pause()

# دالة مخصصة لتبديل حالة التوقف وإظهار/إخفاء الواجهة
func toggle_pause() -> void:
	var is_paused: bool = not get_tree().paused
	get_tree().paused = is_paused
	
	if has_node("CanvasLayer"):
		if is_paused:
			$CanvasLayer.show()
		else:
			$CanvasLayer.hide()

# دالة زر الاستئناف (Resume) عند ربط إشارة pressed
func _on_resume_pressed() -> void:
	toggle_pause()

# دالة زر العودة للقائمة الرئيسية (Main Menu) عند ربط إشارة pressed
func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	if has_node("CanvasLayer"):
		$CanvasLayer.hide()
	
	# الانتقال إلى مشهد القائمة الرئيسية
	get_tree().change_scene_to_file("res://القائمات/القائمه الرائيسيه/القائمه الرائيسيه.tscn")





func _on_opsions_pressed() -> void:
	hide() # إخفاء قائمة التوقف
	if options_menu:
		get_tree().change_scene_to_file("res://القائمات/القائمه الاعدادات/options_menu.tscn")
