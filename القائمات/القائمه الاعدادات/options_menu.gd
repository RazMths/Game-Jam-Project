extends Control
@export var pause_menu: Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_check_box_toggled(toggled_on: bool) -> void:
	
	AudioServer.set_bus_mute(0, toggled_on)
	
	pass # Replace with function body.


func _on_h_slider_value_changed(value: float) -> void:
	
	AudioServer.set_bus_volume_db(0,value/0)
	
	pass # Replace with function body.


func _on_check_button_pressed() -> void:
	
	DisplayServer.window_set_size(Vector2i(1280,720))
	
	pass # Replace with function body.


func _on_resume_pressed() -> void:
	
	
	pass # Replace with function body.



# 📌 متغير يتذكر القائمة السابقة
var previous_menu: Control = null

# 📌 دالة تفتح الإعدادات وتخزن القائمة التي أدت إليها
func open_from(caller: Control) -> void:
	previous_menu = caller
	if previous_menu:
		previous_menu.hide() # إخفاء الشاشة التي أتينا منها
	show() # إظهار الإعدادات

# 📌 عند الضغط على زر العودة/الخروج
func _on_back_pressed() -> void:
	hide()
	if previous_menu:
		previous_menu.show() # العودة للشاشة السابقة مباشرة
