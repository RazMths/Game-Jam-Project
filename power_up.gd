extends Area2D

@export var time_to_add: float = 15.0 # الثواني التي يزيدها المصباح/الشرارة

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	# إذا لمس اللاعب الـ Power-up
	if body.has_method("add_fear_time"):
		body.add_fear_time(time_to_add)
		
		# (اختياري) إطلاق موجة صدى ناعمة في مكان الـ PowerUp عند أخذها
		if body.has_method("spawn_echo"):
			body.spawn_echo(200.0)
			
		queue_free() # اختفاء عنصر الـ Power-up
