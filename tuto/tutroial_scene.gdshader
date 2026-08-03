shader_type canvas_item;

uniform vec2 circle_center = vec2(0.5, 0.5); // مركز الدائرة
uniform float circle_size : hint_range(0.0, 2.0) = 0.0; // تبدأ مغلقة (0.0)
uniform float screen_aspect = 1.777; // نسبة أبعاد الشاشة (16:9)

void fragment() {
    vec2 uv = UV;
    // تصحيح الأبعاد لتظل الدائرة كروية
    uv.x = (uv.x - circle_center.x) * screen_aspect + circle_center.x;
    
    float dist = distance(uv, circle_center);
    
    // ما داخل الدائرة أبيض، وما خارجه شفاف
    if (dist < circle_size) {
        COLOR = vec4(0.3, 0.3, 0.3, 1.0); // دائرة بيضاء
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0); // باقي الشاشة شفاف
    }
}