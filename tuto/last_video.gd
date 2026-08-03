extends Node2D
@onready var v_box_container: VBoxContainer = $CanvasLayer/Control/VBoxContainer
@onready var video: VideoStreamPlayer = $video

@onready var restart_button: Button = $CanvasLayer/Control/VBoxContainer/RestartButton
@onready var quit_button: Button = $CanvasLayer/Control/VBoxContainer/QuitButton

func _ready() -> void:
	v_box_container.visible = false
	video.play()
	video.finished.connect(func():
		v_box_container.visible = true
		)
	
	restart_button.pressed.connect(func():
		get_tree().change_scene_to_file("res://القائمات/القائمه الرائيسيه/main_menu.tscn")
		)
	
	quit_button.pressed.connect(func():
		get_tree().quit()
		)
	
