shader_type canvas_item;

uniform float circle_size : hint_range(0.0, 1.5) = 0.0; // حجم الدائرة (0 مخفية، 1.5 تغطي الشاشة)
uniform vec2 circle_center = vec2(0.5, 0.5);             // مركز الدائرة (مقاس من 0 إلى 1)
uniform float screen_aspect = 1.7778;                     // نسبة العرض إلى الارتفاع (16:9)

void fragment() {
    // تعديل الإحداثيات لتكون الدائرة متناسقة الأبعاد وليست بيضاوية
    vec2 uv = UV;
    uv.x = (uv.x - 0.5) * screen_aspect + 0.5;
    
    vec2 center = circle_center;
    center.x = (center.x - 0.5) * screen_aspect + 0.5;

    float dist = distance(uv, center);
    
    // رسم دائرة بيضاء بحواف ناعمة جداً
    float alpha = smoothstep(circle_size, circle_size - 0.02, dist);
    
    COLOR = vec4(0.3, 0.3, 0.3, alpha); // لون أبيض
}