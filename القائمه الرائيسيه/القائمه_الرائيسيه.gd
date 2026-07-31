extends Control






func _on_texture_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_opsions_pressed() -> void:
	pass # Replace with function body.
