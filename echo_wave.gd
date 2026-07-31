extends Area2D

var max_radius: float = 180.0
var current_radius: float = 0.0
var expansion_speed: float = 350.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# 1. تكبير قطر الدائرة تدريجياً
	current_radius += expansion_speed * delta
	
	# تحديث حجم دائرة الاصطدام في الفيزياء
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = current_radius
	
	# إعادة رسم خط الدائرة المرئي
	queue_redraw()
	
	if current_radius >= max_radius:
		queue_free()

func _draw() -> void:
	# رسم الحلقة الضوئية للموجة
	var alpha = 1.0 - (current_radius / max_radius)
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, Color(0, 0.9, 1.0, alpha), 2.0)

func _on_body_entered(body: Node) -> void:
	# إذا لمست الموجة منصة، نطلب من المنصة أن تظهر!
	if body.has_method("reveal_platform"):
		body.reveal_platform()
